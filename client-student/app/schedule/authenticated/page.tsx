'use client';

import React, { Fragment, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService, scheduleService, assessmentScheduleService } from '@/lib/api';
import { exportScheduleToPdf } from '@/lib/exportPdf';
import { exportScheduleToExcel } from '@/lib/exportExcel';
import { exportAssessmentScheduleToPdf } from '@/lib/exportAssessmentPdf';
import { exportAssessmentScheduleToExcel } from '@/lib/exportAssessmentExcel';
import GroupFilter from '@/components/student/GroupFilter';
import ScheduleTable from '@/components/student/ScheduleTable';
import AssessmentScheduleTable from '@/components/student/AssessmentScheduleTable';
import { scheduleWebSocket } from '@/lib/websocket';
import { headerStyles, buttonStyles, COLORS, messageStyles } from '@/utils/styles';
import { usePrevious } from '@/hooks/usePrevious';
import { getCacheKey, saveToCache, loadFromCache, saveSchedulePrefs, loadSchedulePrefs, clearUserCache } from '@/hooks/useScheduleCache';
import { filterSchedulesForUser, filterAssessmentsForUser } from '@/utils/scheduleFilters';
import { useScheduleExport } from '@/hooks/useScheduleExport';
import type { User } from '@/types/auth';
import type { Schedule, AssessmentSchedule } from '@/types/schedule';

export default function StudentSchedule() {
  const router = useRouter();
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [filteredSchedules, setFilteredSchedules] = useState<Schedule[]>([]);
  const [assessmentSchedules, setAssessmentSchedules] = useState<AssessmentSchedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedGroup, setSelectedGroup] = useState<string>('all');
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [userGroupCode, setUserGroupCode] = useState<string | null>(null);
  const [isOnline, setIsOnline] = useState(true);
  const [showExportMenu, setShowExportMenu] = useState(false);
  const [wsConnected, setWsConnected] = useState(false);
  const exportMenuRef = useRef<HTMLDivElement>(null);
  const isFetchingRef = useRef(false); // Flag pentru a preveni cereri duplicate
  const [showSchedule, setShowSchedule] = useState(false); // Control pentru afișarea orarului sau butoanelor
  // State pentru filtrarea schedule-urilor
  const [selectedAcademicYear, setSelectedAcademicYear] = useState<number | null>(null);
  const [selectedSemester, setSelectedSemester] = useState<string | null>(null);
  const [selectedCycleType, setSelectedCycleType] = useState<string | null>(null);
  // Ref-uri pentru valorile curente folosite în callback-ul WebSocket
  const selectedAcademicYearRef = useRef(selectedAcademicYear);
  const selectedSemesterRef = useRef(selectedSemester);
  const selectedCycleTypeRef = useRef(selectedCycleType);
  const prevSelectedSemester = usePrevious(selectedSemester);
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [dayFilter, setDayFilter] = useState<string | 'all'>('all');
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  
  // Verifică dacă trebuie să afișăm evaluările periodice / sesiunea
  // (pentru orice an și pentru ciclurile F / FR)
  const isAssessmentSchedule =
    selectedSemester === 'assessments1' ||
    selectedSemester === 'assessments2' ||
    selectedSemester === 'exams';



  // Gestionare buton "back" din browser
  useEffect(() => {
    const handlePopState = (event: PopStateEvent) => {
      // Când utilizatorul apasă "back", revenim la butoanele de ciclu
      // NU resetăm selectedAcademicYear - acesta a fost determinat automat pe baza grupei
      // și trebuie să rămână setat pentru ca butoanele să funcționeze
      if (showSchedule) {
        setShowSchedule(false);
        // Resetăm doar semestrul și ciclul, nu și anul
        setSelectedSemester(null);
        setSelectedCycleType(null);
        // Nu mai resetăm ref-urile - usePrevious se ocupă de asta
      }
    };

    window.addEventListener('popstate', handlePopState);

    return () => {
      window.removeEventListener('popstate', handlePopState);
    };
  }, [showSchedule]);

  // Verificare status conexiune online/offline
  useEffect(() => {
    const updateOnlineStatus = () => {
      setIsOnline(navigator.onLine);
    };

    setIsOnline(navigator.onLine);
    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);

    return () => {
      window.removeEventListener('online', updateOnlineStatus);
      window.removeEventListener('offline', updateOnlineStatus);
    };
  }, []);

 
  useEffect(() => {
    const hasToken = authService.isAuthenticated();
    
   
    if (!hasToken) {
      router.replace('/schedule');
      return;
    }

    // Verifică dacă token-ul este expirat local (fără server)
    if (authService.isTokenExpired()) {
      console.error('Token expirat local, redirecționare la pagina publică');
      authService.logout();
      router.replace('/schedule');
      return;
    }

    // Dacă există token și nu este expirat local, încearcă să obțină datele utilizatorului
    // Dacă serverul este oprit, permite utilizatorului să rămână pe pagină
    authService
      .getCurrentUser()
      .then((user: User) => {
        // Token-ul este valid - utilizatorul este autentificat
        setIsAuthenticated(true);
        const email = authService.getUserEmail();
        setUserEmail(email);
        
        if (user.group_code) {
          setUserGroupCode(user.group_code);
          setSelectedGroup(user.group_code);
          // Salvează group_code în localStorage pentru utilizare offline
          authService.setUserGroupCode(user.group_code);
          
          // Determină automat anul academic, semestrul și ciclul pe baza schedule-urilor pentru grupa utilizatorului
          scheduleService.getScheduleByGroup(user.group_code)
            .then((schedules) => {
              if (schedules && schedules.length > 0) {
                // Numără frecvența fiecărui an, semestru și ciclu
                const yearCounts = new Map<number, number>();
                const semesterCounts = new Map<string, number>();
                const cycleCounts = new Map<string, number>();

                schedules.forEach((schedule) => {
                  if (schedule.academic_year) {
                    yearCounts.set(schedule.academic_year, (yearCounts.get(schedule.academic_year) || 0) + 1);
                  }
                  if (schedule.semester) {
                    semesterCounts.set(schedule.semester, (semesterCounts.get(schedule.semester) || 0) + 1);
                  }
                  if (schedule.cycle_type) {
                    cycleCounts.set(schedule.cycle_type, (cycleCounts.get(schedule.cycle_type) || 0) + 1);
                  }
                });

                // Găsește anul cel mai frecvent
                let mostFrequentYear: number | null = null;
                let maxCount = 0;
                yearCounts.forEach((count, year) => {
                  if (count > maxCount) {
                    maxCount = count;
                    mostFrequentYear = year;
                  }
                });

                // Găsește semestrul cel mai frecvent
                let mostFrequentSemester: string | null = null;
                let maxSemesterCount = 0;
                semesterCounts.forEach((count, semester) => {
                  if (count > maxSemesterCount) {
                    maxSemesterCount = count;
                    mostFrequentSemester = semester;
                  }
                });

                // Găsește ciclul cel mai frecvent
                let mostFrequentCycle: string | null = null;
                let maxCycleCount = 0;
                cycleCounts.forEach((count, cycle) => {
                  if (count > maxCycleCount) {
                    maxCycleCount = count;
                    mostFrequentCycle = cycle;
                  }
                });

                // Setează valorile detectate (pentru a fi folosite când utilizatorul apasă pe butoane)
                if (mostFrequentYear) {
                  setSelectedAcademicYear(mostFrequentYear);
                  console.log(`[Auto-detect] Anul determinat din orar pentru grupa "${user.group_code}": ${mostFrequentYear} (${maxCount} schedule-uri)`);
                }
                
                if (mostFrequentSemester) {
                  setSelectedSemester(mostFrequentSemester);
                  console.log(`[Auto-detect] Semestrul determinat din orar: ${mostFrequentSemester} (${maxSemesterCount} schedule-uri)`);
                }
                
                if (mostFrequentCycle) {
                  setSelectedCycleType(mostFrequentCycle);
                  console.log(`[Auto-detect] Ciclul determinat din orar: ${mostFrequentCycle} (${maxCycleCount} schedule-uri)`);
                } else {
                  // Dacă nu există ciclu, setăm implicit F
                  setSelectedCycleType('F');
                }
              } else {
                console.log(`[Auto-detect] Nu există schedule-uri pentru grupa "${user.group_code}"`);
              }
            })
            .catch((err) => {
              console.warn('[Auto-detect] Eroare la determinarea automată a anului:', err);
            });
        }
      })
      .catch((err: any) => {
        // Verifică tipul erorii
        const isUnauthorized = err.response?.status === 401;
        const isNetworkError = !err.response || err.code === 'ECONNREFUSED' || err.code === 'ERR_NETWORK' || err.message?.includes('Network Error');
        
        if (isUnauthorized) {
          // Token-ul este invalid sau expirat (401) - redirecționează la pagina publică
          console.error('Token invalid sau expirat (401), redirecționare la pagina publică:', err);
          authService.logout();
          router.replace('/schedule');
        } else if (isNetworkError) {
          // Eroare de rețea (server oprit) - permite utilizatorului să rămână pe pagină
          // Folosește token-ul din localStorage și permite funcționarea offline
          console.warn('Server oprit sau eroare de rețea, se continuă în modul offline:', err);
          setIsAuthenticated(true);
          const email = authService.getUserEmail();
          setUserEmail(email);
          const savedGroupCode = authService.getUserGroupCode();
          if (savedGroupCode) {
            setUserGroupCode(savedGroupCode);
            setSelectedGroup(savedGroupCode);
            console.log('✓ Group code încărcat din localStorage pentru modul offline:', savedGroupCode);
          }
          // Restaurăm an/semestru/ciclu din localStorage ca butoanele să funcționeze offline
          const prefs = loadSchedulePrefs(savedGroupCode ?? null, savedGroupCode ?? null);
          if (prefs) {
            setSelectedAcademicYear(prefs.academicYear);
            setSelectedSemester(prefs.semester);
            setSelectedCycleType(prefs.cycleType);
            console.log('✓ Preferințe orar restaurate din cache pentru modul offline:', prefs);
          } else {
            // Fallback: an 1, semestru toamnă, F - permite acces la orar din cache
            setSelectedAcademicYear(1);
            setSelectedSemester('semester1');
            setSelectedCycleType('F');
            console.log('✓ Modul offline: folosesc an 1, semester1, F (nu existau preferințe în cache)');
          }
        } else {
          // Altă eroare - tratează ca token invalid pentru siguranță
          console.error('Eroare necunoscută la verificarea token-ului, redirecționare:', err);
          authService.logout();
          router.replace('/schedule');
        }
      });
  }, [router]);

  // Salvează preferințele (an, semestru, ciclu) în localStorage când se schimbă - pentru modul offline
  useEffect(() => {
    if (selectedAcademicYear == null || !selectedSemester || !selectedCycleType || !userGroupCode) return;
    saveSchedulePrefs(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType);
  }, [selectedAcademicYear, selectedSemester, selectedCycleType, userGroupCode]);

  useEffect(() => {
    const fetchSchedules = async (showLoading = true) => {
      // Previne cereri duplicate simultane
      if (isFetchingRef.current) {
        console.log('⏭️ Cerere deja în curs, se ignoră...');
        return;
      }
      
      isFetchingRef.current = true;
      
      try {
        // Verifică că avem parametrii necesari
        if (!selectedAcademicYear || !selectedSemester || !selectedCycleType) {
          if (showLoading) {
            setLoading(false);
          }
          return;
        }

        // Verifică conexiunea - dacă nu există, încearcă să încarce din cache
        if (!isOnline) {
          console.log('[Cache] Nu există conexiune - încerc să încarc din cache');
          const cachedData = loadFromCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, false) as Schedule[] | null;
          if (cachedData && cachedData.length > 0) {
            setSchedules(cachedData);
            setFilteredSchedules(cachedData);
            setError('Datele sunt afișate din cache (fără conexiune la server).');
            console.log('[Cache] Date încărcate din cache pentru modul offline');
          } else {
            setError('Nu există conexiune la internet și nu există date în cache.');
          }
          if (showLoading) {
            setLoading(false);
          }
          return;
        }

        // Încearcă să încarce datele de pe server
        try {
          if (showLoading) {
          setLoading(true);
          }
          
          // Construiește parametrii de filtrare dacă sunt setate
          const filterParams: {
            academic_year?: number;
            semester?: string;
            cycle_type?: string;
          } = {};
          
          if (selectedAcademicYear !== null && selectedAcademicYear !== undefined) {
            filterParams.academic_year = selectedAcademicYear;
          }
          if (selectedSemester) {
            filterParams.semester = selectedSemester;
          }
          if (selectedCycleType) {
            filterParams.cycle_type = selectedCycleType;
          }
          
          // Folosește filtrarea doar dacă toate valorile sunt setate
          const data = await scheduleService.getAllSchedules(
            Object.keys(filterParams).length > 0 ? filterParams : undefined
          );
          const filteredData = filterSchedulesForUser(data, userGroupCode);
          
          // Salvează datele în cache
          saveToCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, false, filteredData);
          
          // Actualizează datele - vor înlocui datele vechi
          setSchedules(filteredData);
          setFilteredSchedules(filteredData);
          setError(''); // Resetează erorile la reîncărcare reușită
        } catch (err: any) {
          // Dacă există eroare de rețea, încearcă să încarce din cache
          const isNetworkError = !err.response || err.code === 'ECONNREFUSED' || err.code === 'ERR_NETWORK' || err.message?.includes('Network Error');
          
          if (isNetworkError) {
            console.log('[Cache] Eroare de rețea - încerc să încarc din cache');
            const cachedData = loadFromCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, false) as Schedule[] | null;
            if (cachedData && cachedData.length > 0) {
              setSchedules(cachedData);
              setFilteredSchedules(cachedData);
              setError('Datele sunt afișate din cache (server indisponibil).');
              console.log('[Cache] Date încărcate din cache după eroare de rețea');
            } else {
              setError(err.response?.data?.detail || 'Eroare la încărcarea orarului și nu există date în cache.');
            }
          } else {
            setError(err.response?.data?.detail || 'Eroare la încărcarea orarului.');
          }
        } finally {
          if (showLoading) {
          setLoading(false);
        }
        }
      } finally {
        isFetchingRef.current = false;
      }
    };

    // Funcție pentru încărcarea evaluărilor periodice
    const fetchAssessmentSchedules = async (showLoading: boolean = true) => {
      // Previne cereri duplicate simultane
      if (isFetchingRef.current) {
        console.log('⏭️ Cerere deja în curs pentru assessments, se ignoră...');
        return;
      }
      
      isFetchingRef.current = true;
      
      try {
        // Verifică că avem parametrii necesari
        if (
          selectedAcademicYear === null ||
          selectedSemester === null ||
          selectedCycleType === null
        ) {
          console.log('[Assessment] Parametrii lipsă, nu încarc datele');
          if (showLoading) {
            setLoading(false);
          }
          return;
        }

        if (showLoading) {
          setLoading(true);
        }

        // Verifică conexiunea - dacă nu există, încearcă să încarce din cache
        if (!isOnline) {
          console.log('[Cache] Nu există conexiune - încerc să încarc assessments din cache');
          const cachedData = loadFromCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, true) as AssessmentSchedule[] | null;
          if (cachedData && cachedData.length > 0) {
            setAssessmentSchedules(cachedData);
            setError('Datele sunt afișate din cache (fără conexiune la server).');
            console.log('[Cache] Assessments încărcate din cache pentru modul offline');
          } else {
            setError('Nu există conexiune la server și nu există date în cache.');
          }
          if (showLoading) {
            setLoading(false);
          }
          return;
        }

        console.log('[Assessment] Încep încărcarea evaluărilor periodice...', {
          academic_year: selectedAcademicYear,
          semester: selectedSemester,
          cycle_type: selectedCycleType,
        });

        // Încearcă să încarce de la server
        const data = await assessmentScheduleService.getAllAssessmentSchedules({
          academic_year: selectedAcademicYear,
          semester: selectedSemester,
          cycle_type: selectedCycleType,
        });
        
        console.log('[Assessment] Date primite de la server:', data);
        
        const filteredData = filterAssessmentsForUser(data, userGroupCode);
        
        console.log('[Assessment] Date filtrate pentru utilizator:', filteredData);
        
        // Salvează datele în cache
        saveToCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, true, filteredData);
        
        // Actualizează datele - vor înlocui datele vechi
        setAssessmentSchedules(filteredData);
        setError(''); // Resetează erorile la reîncărcare reușită
      } catch (err: any) {
        console.error('Eroare la încărcarea evaluărilor periodice:', err);
        
        // Dacă există eroare de rețea, încearcă să încarce din cache
        const isNetworkError = !err.response || err.code === 'ECONNREFUSED' || err.code === 'ERR_NETWORK' || err.message?.includes('Network Error');
        
        if (isNetworkError) {
          console.log('[Cache] Eroare de rețea - încerc să încarc assessments din cache');
          const cachedData = loadFromCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, true) as AssessmentSchedule[] | null;
          if (cachedData && cachedData.length > 0) {
            setAssessmentSchedules(cachedData);
            setError('Datele sunt afișate din cache (server indisponibil).');
            console.log('[Cache] Assessments încărcate din cache după eroare de rețea');
          } else {
            setError(err.response?.data?.detail || 'Eroare la încărcarea evaluărilor periodice și nu există date în cache.');
          }
        } else {
          setError(err.response?.data?.detail || 'Eroare la încărcarea evaluărilor periodice.');
        }
      } finally {
        isFetchingRef.current = false;
        if (showLoading) {
          setLoading(false);
        }
      }
    };

    // Încărcare inițială - doar dacă există o selecție (nu încărca toate schedule-urile la start)
    // Schedule-urile vor fi încărcate când studentul selectează un an/semestru/ciclu
    if (selectedAcademicYear !== null && selectedSemester !== null && selectedCycleType !== null) {
      // Folosim usePrevious hook pentru a obține valoarea anterioară
      const prevSemester = prevSelectedSemester;
      
      // Detectăm dacă semestrul s-a schimbat
      const semesterChanged = prevSemester !== null && prevSemester !== undefined && prevSemester !== selectedSemester;
      
      // Detectăm dacă tipul de orar s-a schimbat (normal ↔ assessment)
      const isAssessmentSemester = selectedSemester === 'assessments1' || 
                                   selectedSemester === 'assessments2' || 
                                   selectedSemester === 'exams';
      const wasAssessmentSemester = prevSemester === 'assessments1' || 
                                    prevSemester === 'assessments2' || 
                                    prevSemester === 'exams';
      const scheduleTypeChanged = semesterChanged && isAssessmentSemester !== wasAssessmentSemester;
      
      console.log(`[Debug] prevSemester=${prevSemester}, selectedSemester=${selectedSemester}, semesterChanged=${semesterChanged}, scheduleTypeChanged=${scheduleTypeChanged}`);
      
      // Resetăm flag-ul de fetching pentru a permite reîncărcarea
      isFetchingRef.current = false;
      
      // IMPORTANT: Nu resetăm datele dacă showSchedule este true
      // Datele vechi vor rămâne afișate până când noile date sunt încărcate de la server
      // Asta previne dispariția orarului când utilizatorul apasă pe alt buton
      if (!showSchedule) {
        // Prima dată sau când revenim la butoane - resetăm toate datele
        console.log('[Reset] Prima dată sau revenire la butoane - resetez toate datele');
        setSchedules([]);
        setFilteredSchedules([]);
        setAssessmentSchedules([]);
        setError('');
      } else if (scheduleTypeChanged) {
        // Când schimbăm tipul de orar (normal ↔ assessment), resetăm doar datele corespunzătoare
        // Dar NU resetăm dacă showSchedule este true - le păstrăm până când noile date sunt încărcate
        console.log(`[Schedule Type Changed] De la ${wasAssessmentSemester ? 'assessment' : 'normal'} la ${isAssessmentSemester ? 'assessment' : 'normal'}`);
        // Nu resetăm datele - le vom înlocui când noile date sunt încărcate
      } else if (semesterChanged) {
        // Semestrul s-a schimbat dar tipul rămâne același
        // NU resetăm datele - le vom înlocui când noile date sunt încărcate
        console.log('[Semester Changed] Semestrul s-a schimbat - NU resetez datele, le înlocuiesc când sunt încărcate');
      }
      
      // Verifică dacă există date în cache pentru semestrul curent
      // Dacă există și serverul nu este disponibil, le încarcă imediat
      const cachedData = isAssessmentSchedule
        ? loadFromCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, true)
        : loadFromCache(userGroupCode, selectedAcademicYear, selectedSemester, selectedCycleType, false);

      if (cachedData && (!isOnline || !navigator.onLine)) {
        console.log('[Cache] Server indisponibil - folosesc date din cache');
        if (isAssessmentSchedule) {
          setAssessmentSchedules(cachedData as AssessmentSchedule[]);
          setError('Datele sunt afișate din cache (server indisponibil).');
        } else {
          const schedulesData = cachedData as Schedule[];
          setSchedules(schedulesData);
          setFilteredSchedules(schedulesData);
          setError('Datele sunt afișate din cache (server indisponibil).');
        }
        setLoading(false);
        return; // Nu mai încărca de la server dacă folosim cache-ul
      }

      // Verifică dacă trebuie să încărce evaluări periodice
      // Încărcăm întotdeauna datele de la server - vor înlocui datele vechi când sunt gata
      console.log(`[Fetch Decision] isAssessmentSchedule=${isAssessmentSchedule}, selectedSemester=${selectedSemester}`);
      if (isAssessmentSchedule) {
        console.log('[Fetch] Apel fetchAssessmentSchedules pentru:', {
          academic_year: selectedAcademicYear,
          semester: selectedSemester,
          cycle_type: selectedCycleType,
        });
        fetchAssessmentSchedules(true);
      } else {
        console.log('[Fetch] Apel fetchSchedules pentru:', {
          academic_year: selectedAcademicYear,
          semester: selectedSemester,
          cycle_type: selectedCycleType,
        });
        fetchSchedules(true);
      }
    }

    // Polling fallback - doar dacă WebSocket-ul nu este conectat (la fiecare 60 secunde)
    const pollingInterval = setInterval(() => {
      if (isOnline && !document.hidden && !scheduleWebSocket.isConnected() && !isFetchingRef.current) {
        console.log('🔄 Polling fallback (WebSocket nu este conectat)');
        fetchSchedules(false);
      }
    }, 60000);

    return () => {
      clearInterval(pollingInterval);
    };
  }, [isOnline, selectedAcademicYear, selectedSemester, selectedCycleType, isAssessmentSchedule]);

  // Actualizează ref-urile când se schimbă valorile
  useEffect(() => {
    selectedAcademicYearRef.current = selectedAcademicYear;
    selectedSemesterRef.current = selectedSemester;
    selectedCycleTypeRef.current = selectedCycleType;
  }, [selectedAcademicYear, selectedSemester, selectedCycleType]);


  // Conectare WebSocket - separat, doar depinde de isOnline pentru a evita conexiuni duplicate
  useEffect(() => {
    if (!isOnline) {
      return;
    }

    // Conectare WebSocket - doar dacă nu este deja conectat
    if (!scheduleWebSocket.isConnected()) {
      scheduleWebSocket.connect();
    }

    // Listener pentru actualizări de orar prin WebSocket
    const unsubscribeScheduleUpdate = scheduleWebSocket.onScheduleUpdate((updatedSchedules) => {
      if (updatedSchedules.length > 0) {
        // Am primit toate schedule-urile (refresh_all) - TREBUIE FILTRATE după semestrul curent
        const year = selectedAcademicYearRef.current;
        const semester = selectedSemesterRef.current;
        const cycle = selectedCycleTypeRef.current;
        
        // Filtrează datele primite după parametrii curenti (an, semestru, ciclu)
        let filteredByParams = updatedSchedules;
        if (year !== null && semester !== null && cycle !== null) {
          filteredByParams = updatedSchedules.filter((s) => 
            s.academic_year === year && 
            s.semester === semester && 
            s.cycle_type === cycle
          );
        }
        
        // Apoi filtrează după grupa utilizatorului (dacă e cazul)
        const filtered = filterSchedulesForUser(filteredByParams, userGroupCode);
        setSchedules(filtered);
        setFilteredSchedules(filtered);
        setError('');
        console.log('✓ Orar actualizat prin WebSocket (refresh_all)');
      } else {
        // Array gol = create/update/delete - reîncarcă datele automat
        const year = selectedAcademicYearRef.current;
        const semester = selectedSemesterRef.current;
        const cycle = selectedCycleTypeRef.current;
        
        // Reîncarcă doar dacă avem parametrii setați și dacă orarul este afișat
        if (year !== null && semester !== null && cycle !== null && showSchedule) {
          console.log('🔄 Reîncărcare automată după create/update/delete prin WebSocket');
          // Reîncarcă datele de la server
          scheduleService.getAllSchedules({
            academic_year: year,
            semester: semester,
            cycle_type: cycle,
          })
            .then((data) => {
              const filtered = filterSchedulesForUser(data, userGroupCode);
              setSchedules(filtered);
              setFilteredSchedules(filtered);
              setError('');
              console.log('✓ Orar reîncărcat după modificare prin WebSocket');
            })
            .catch((err) => {
              console.error('Eroare la reîncărcarea orarului după modificare:', err);
            
            });
        }
      }
    });

    // Listener pentru conectare WebSocket
    const unsubscribeConnect = scheduleWebSocket.onConnect(() => {
      setWsConnected(true);
      console.log('✓ WebSocket conectat');
    });

    // Reîncărcare automată când pagina devine vizibilă din nou
    const handleVisibilityChange = () => {
      if (!document.hidden && isOnline && !scheduleWebSocket.isConnected()) {
        scheduleWebSocket.connect();
      }
    };

    // Reîncărcare automată când conexiunea revine
    const handleOnline = () => {
      if (isOnline && !scheduleWebSocket.isConnected()) {
        scheduleWebSocket.connect();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('online', handleOnline);

    // Cleanup - deconectează când componenta se demontă
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('online', handleOnline);
      unsubscribeScheduleUpdate();
      unsubscribeConnect();
      // Deconectează WebSocket când componenta se demontă pentru a evita conexiuni multiple
      scheduleWebSocket.disconnect();
    };
  }, [isOnline]); // Redus dependențele - doar isOnline

  useEffect(() => {
    let result = schedules;

    // Filtrare după grupă (utilizată în modul public; în modul logat selectedGroup este grupa utilizatorului)
    if (selectedGroup !== 'all') {
      result = result.filter((s) => s.group.code === selectedGroup);
    }

    // Filtrare după zi (dacă este activată)
    if (dayFilter !== 'all') {
      result = result.filter((s) => s.day === dayFilter);
    }

    setFilteredSchedules(result);
  }, [selectedGroup, schedules, dayFilter]);

  const uniqueGroups = useMemo(() => {
    // Pentru evaluările periodice, extragem grupele din groups_composition
    if (isAssessmentSchedule) {
      const allGroups = new Set<string>();
      assessmentSchedules.forEach((assessment) => {
        const groups = assessment.groups_composition
          .split(',')
          .map((g) => g.trim())
          .filter((g) => g.length > 0);
        groups.forEach((group) => allGroups.add(group));
      });
      return Array.from(allGroups).sort();
    }

    // Pentru orare normale, creează un map pentru a păstra ordinea grupurilor după groupId
    const groupMap = new Map<number, string>();
    for (const schedule of schedules) {
      if (!groupMap.has(schedule.group.id)) {
        groupMap.set(schedule.group.id, schedule.group.code);
      }
    }
    
    // Citește ordinea grupurilor din localStorage (aceeași cheie ca în Admin)
    const STORAGE_KEY = 'scheduleGroupsOrder';
    const savedOrder = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null;
    let groupOrder: number[] = [];
    
    if (savedOrder) {
      try {
        groupOrder = JSON.parse(savedOrder);
      } catch (e) {
        console.error('Eroare la citirea ordinii grupurilor din localStorage:', e);
      }
    }
    
    // Obține toate groupId-urile
    const allGroupIds = Array.from(groupMap.keys());
    
    // Sortează după ordinea salvată în localStorage (ca în Admin)
    const sortedGroupIds = allGroupIds.sort((a, b) => {
      const indexA = groupOrder.indexOf(a);
      const indexB = groupOrder.indexOf(b);
      
      // Dacă ambele sunt în ordinea salvată, sortăm după poziția lor
      if (indexA !== -1 && indexB !== -1) {
        return indexA - indexB;
      }
      
      // Dacă doar unul este în ordinea salvată, îl punem primul
      if (indexA !== -1) return -1;
      if (indexB !== -1) return 1;
      
      // Dacă niciunul nu este în ordinea salvată, sortăm după ID (pentru grupe noi)
      return a - b;
    });
    
    return sortedGroupIds.map((groupId) => groupMap.get(groupId)!);
  }, [schedules, assessmentSchedules, isAssessmentSchedule]);


  const handleLogout = () => {
    setIsLoggingOut(true); // Previne re-renderizarea în timpul logout-ului
    clearUserCache(userGroupCode); // Șterge cache-ul la logout
    authService.logout();
    setIsAuthenticated(false);
    setUserEmail(null);
    setUserGroupCode(null);
    setSelectedGroup('all');
    setShowSchedule(false);
    setDayFilter('all');
    // Redirecționează la pagina de login după logout
    router.replace('/login');
  };

  // Închide meniul de export când se face click în afara lui
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (exportMenuRef.current && !exportMenuRef.current.contains(event.target as Node)) {
        setShowExportMenu(false);
      }
    };

    if (showExportMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showExportMenu]);

  // Hook pentru export
  const { handleExportPDF, handleExportExcel } = useScheduleExport({
    schedules,
    filteredSchedules,
    assessmentSchedules,
    selectedGroup,
    uniqueGroups: uniqueGroups,
    selectedAcademicYear,
    selectedSemester,
    selectedCycleType,
    isAssessmentSchedule,
    onExportMenuClose: () => setShowExportMenu(false),
  });

  // Filtrare rapidă pe ziua curentă (doar pentru utilizator autenticat)
  const handleToggleTodayFilter = () => {
    if (dayFilter === 'all') {
      const today = new Date().getDay(); // 0 = Duminică, 1 = Luni, ...
      const dayMap: Record<number, string> = {
        1: 'Luni',
        2: 'Marți',
        3: 'Miercuri',
        4: 'Joi',
        5: 'Vineri',
        6: 'Sâmbătă',
      };
      const todayName = dayMap[today];
      if (todayName) {
        setDayFilter(todayName);
      }
    } else {
      setDayFilter('all');
    }
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: COLORS.background }}>
      <header
        style={headerStyles.header}
      >
        <div>
          <h1 style={headerStyles.title}>
            Orar 
          </h1>
        
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          {!isLoggingOut && (
            <>
              {userEmail && (
                <span style={{ 
                  color: COLORS.textSecondary, 
                  fontSize: '0.9rem',
                  fontWeight: '400',
                }}>
                  {userEmail}
                </span>
              )}
              <button
                onClick={handleLogout}
                onMouseEnter={(e) => {
                  e.currentTarget.style.backgroundColor = COLORS.dangerHover;
                  e.currentTarget.style.boxShadow = COLORS.shadow;
                  e.currentTarget.style.transform = 'translateY(-1px)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.backgroundColor = COLORS.danger;
                  e.currentTarget.style.boxShadow = COLORS.shadowSm;
                  e.currentTarget.style.transform = 'translateY(0)';
                }}
                style={{
                  ...buttonStyles.danger,
                }}
              >
                Deconectare
              </button>
            </>
          )}
        </div>
      </header>

      <main style={{ padding: '2rem', maxWidth: '1400px', margin: '0 auto' }}>
        {error && (
          <div style={messageStyles.error}>
            {error}
          </div>
        )}

        {/* Container cu butoane pentru selectarea orarului - DOAR pentru utilizatorii autentificați */}
        {!showSchedule && (
          <div
            style={{
              backgroundColor: 'white',
              borderRadius: '12px',
              boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
              padding: '2rem',
              margin: '0 auto',
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
              gap: '1.25rem',
              maxWidth: '1200px',
            }}
          >
            {/* Semestrul de toamnă */}
            <button
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-4px)';
                e.currentTarget.style.boxShadow = '0 8px 20px rgba(59, 130, 246, 0.3)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(59, 130, 246, 0.15)';
              }}
              style={{
                backgroundColor: '#3b82f6',
                color: 'white',
                border: 'none',
                borderRadius: '12px',
                padding: '1.5rem',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'flex-start',
                gap: '0.75rem',
                cursor: 'pointer',
                transition: 'all 0.3s ease',
                boxShadow: '0 4px 12px rgba(59, 130, 246, 0.15)',
                position: 'relative',
                overflow: 'hidden',
              }}
              onClick={() => {
                if (selectedAcademicYear == null) setSelectedAcademicYear(1);
                setSelectedSemester('semester1');
                setSelectedCycleType('F');
                setShowSchedule(true);
                window.history.pushState({ showSchedule: true }, '', window.location.href);
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%' }}>
                <div style={{ 
                  backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                  borderRadius: '10px', 
                  padding: '0.75rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                  </svg>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.75rem', opacity: 0.9, fontWeight: '500', marginBottom: '0.25rem' }}>Semestrul</div>
                  <div style={{ fontSize: '1rem', fontWeight: '700', lineHeight: '1.3' }}>Orar Semestrul de toamnă</div>
                </div>
              </div>
            </button>

            {/* Evaluarea periodică nr. 1 */}
            <button
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-4px)';
                e.currentTarget.style.boxShadow = '0 8px 20px rgba(139, 92, 246, 0.3)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(139, 92, 246, 0.15)';
              }}
              style={{
                backgroundColor: '#8b5cf6',
                color: 'white',
                border: 'none',
                borderRadius: '12px',
                padding: '1.5rem',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'flex-start',
                gap: '0.75rem',
                cursor: 'pointer',
                transition: 'all 0.3s ease',
                boxShadow: '0 4px 12px rgba(139, 92, 246, 0.15)',
                position: 'relative',
                overflow: 'hidden',
              }}
              onClick={() => {
                if (selectedAcademicYear == null) setSelectedAcademicYear(1);
                setSelectedSemester('assessments1');
                setSelectedCycleType('F');
                setShowSchedule(true);
                window.history.pushState({ showSchedule: true }, '', window.location.href);
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%' }}>
                <div style={{ 
                  backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                  borderRadius: '10px', 
                  padding: '0.75rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                  </svg>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.75rem', opacity: 0.9, fontWeight: '500', marginBottom: '0.25rem' }}>Evaluare</div>
                  <div style={{ fontSize: '1rem', fontWeight: '700', lineHeight: '1.3' }}>Orar evaluarea periodică nr. 1</div>
                </div>
              </div>
            </button>

            {/* Evaluarea periodică nr. 2 */}
            <button
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-4px)';
                e.currentTarget.style.boxShadow = '0 8px 20px rgba(168, 85, 247, 0.3)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(168, 85, 247, 0.15)';
              }}
              style={{
                backgroundColor: '#a855f7',
                color: 'white',
                border: 'none',
                borderRadius: '12px',
                padding: '1.5rem',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'flex-start',
                gap: '0.75rem',
                cursor: 'pointer',
                transition: 'all 0.3s ease',
                boxShadow: '0 4px 12px rgba(168, 85, 247, 0.15)',
                position: 'relative',
                overflow: 'hidden',
              }}
              onClick={() => {
                if (selectedAcademicYear == null) setSelectedAcademicYear(1);
                setSelectedSemester('assessments2');
                setSelectedCycleType('F');
                setShowSchedule(true);
                window.history.pushState({ showSchedule: true }, '', window.location.href);
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%' }}>
                <div style={{ 
                  backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                  borderRadius: '10px', 
                  padding: '0.75rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                  </svg>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.75rem', opacity: 0.9, fontWeight: '500', marginBottom: '0.25rem' }}>Evaluare</div>
                  <div style={{ fontSize: '1rem', fontWeight: '700', lineHeight: '1.3' }}>Orar evaluarea periodică nr. 2</div>
                </div>
              </div>
            </button>

            {/* Sesiunea de examinare */}
            <button
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-4px)';
                e.currentTarget.style.boxShadow = '0 8px 20px rgba(239, 68, 68, 0.3)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(239, 68, 68, 0.15)';
              }}
              style={{
                backgroundColor: '#ef4444',
                color: 'white',
                border: 'none',
                borderRadius: '12px',
                padding: '1.5rem',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'flex-start',
                gap: '0.75rem',
                cursor: 'pointer',
                transition: 'all 0.3s ease',
                boxShadow: '0 4px 12px rgba(239, 68, 68, 0.15)',
                position: 'relative',
                overflow: 'hidden',
              }}
              onClick={() => {
                if (selectedAcademicYear == null) setSelectedAcademicYear(1);
                setSelectedSemester('exams');
                setSelectedCycleType('F');
                setShowSchedule(true);
                window.history.pushState({ showSchedule: true }, '', window.location.href);
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%' }}>
                <div style={{ 
                  backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                  borderRadius: '10px', 
                  padding: '0.75rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="12" y1="18" x2="12" y2="12"></line>
                    <line x1="9" y1="15" x2="15" y2="15"></line>
                  </svg>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.75rem', opacity: 0.9, fontWeight: '500', marginBottom: '0.25rem' }}>Sesiune</div>
                  <div style={{ fontSize: '1rem', fontWeight: '700', lineHeight: '1.3' }}>Orar Sesiunea de examinare</div>
                </div>
              </div>
            </button>

            {/* Semestrul de primăvară */}
            <button
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-4px)';
                e.currentTarget.style.boxShadow = '0 8px 20px rgba(34, 197, 94, 0.3)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(34, 197, 94, 0.15)';
              }}
              style={{
                backgroundColor: '#22c55e',
                color: 'white',
                border: 'none',
                borderRadius: '12px',
                padding: '1.5rem',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'flex-start',
                gap: '0.75rem',
                cursor: 'pointer',
                transition: 'all 0.3s ease',
                boxShadow: '0 4px 12px rgba(34, 197, 94, 0.15)',
                position: 'relative',
                overflow: 'hidden',
              }}
              onClick={() => {
                if (selectedAcademicYear == null) setSelectedAcademicYear(1);
                setSelectedSemester('semester2');
                setSelectedCycleType('F');
                setShowSchedule(true);
                window.history.pushState({ showSchedule: true }, '', window.location.href);
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%' }}>
                <div style={{ 
                  backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                  borderRadius: '10px', 
                  padding: '0.75rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                    <path d="M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01M16 18h.01"></path>
                  </svg>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.75rem', opacity: 0.9, fontWeight: '500', marginBottom: '0.25rem' }}>Semestrul</div>
                  <div style={{ fontSize: '1rem', fontWeight: '700', lineHeight: '1.3' }}>Orar Semestrul de primăvară</div>
                </div>
              </div>
            </button>
          </div>
        )}

        {/* Orarul - se afișează doar când showSchedule este true */}
        {showSchedule && (
          <>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', width: '100%', marginBottom: '1rem', marginTop: '0', position: 'relative' }}>
          {/* Filtrare rapidă pe ziua curentă (orarul de azi) - doar pentru orare normale, nu pentru evaluări */}
          {!isAssessmentSchedule ? (
            <button
              onClick={handleToggleTodayFilter}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = COLORS.primaryHover;
                e.currentTarget.style.boxShadow = COLORS.shadow;
                e.currentTarget.style.transform = 'translateY(-1px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = COLORS.primary;
                e.currentTarget.style.boxShadow = COLORS.shadowSm;
                e.currentTarget.style.transform = 'translateY(0)';
              }}
              style={{
                ...buttonStyles.primary,
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
              }}
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
              </svg>
              {dayFilter === 'all' ? 'Orarul de azi' : dayFilter}
            </button>
          ) : null}
          
          <div ref={exportMenuRef} style={{ position: 'relative' }}>
            <button
              onClick={() => setShowExportMenu(!showExportMenu)}
              disabled={isAssessmentSchedule ? assessmentSchedules.length === 0 : filteredSchedules.length === 0}
              onMouseEnter={(e) => {
                const hasData = isAssessmentSchedule ? assessmentSchedules.length > 0 : filteredSchedules.length > 0;
                if (hasData) {
                  e.currentTarget.style.backgroundColor = COLORS.successHover;
                  e.currentTarget.style.boxShadow = COLORS.shadow;
                  e.currentTarget.style.transform = 'translateY(-1px)';
                }
              }}
              onMouseLeave={(e) => {
                const hasData = isAssessmentSchedule ? assessmentSchedules.length > 0 : filteredSchedules.length > 0;
                if (hasData) {
                  e.currentTarget.style.backgroundColor = COLORS.success;
                  e.currentTarget.style.boxShadow = COLORS.shadowSm;
                  e.currentTarget.style.transform = 'translateY(0)';
                }
              }}
              style={{
                ...((isAssessmentSchedule ? assessmentSchedules.length === 0 : filteredSchedules.length === 0) ? buttonStyles.disabled : {}),
                ...buttonStyles.success,
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                backgroundColor: (isAssessmentSchedule ? assessmentSchedules.length === 0 : filteredSchedules.length === 0) ? COLORS.textSecondary : COLORS.success,
                opacity: (isAssessmentSchedule ? assessmentSchedules.length === 0 : filteredSchedules.length === 0) ? 0.6 : 1,
              }}
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              
            </button>
            {showExportMenu && ((isAssessmentSchedule && assessmentSchedules.length > 0) || (!isAssessmentSchedule && filteredSchedules.length > 0)) && (
              <div
                style={{
                  position: 'absolute',
                  top: '100%',
                  right: 0,
                  marginTop: '0.5rem',
                  backgroundColor: COLORS.white,
                  border: `1px solid ${COLORS.border}`,
                  borderRadius: '8px',
                  boxShadow: COLORS.shadowLg,
                  zIndex: 1000,
                  minWidth: '150px',
                  overflow: 'hidden',
                }}
              >
                <button
                  onClick={handleExportPDF}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    textAlign: 'left',
                    border: 'none',
                    backgroundColor: 'transparent',
                    cursor: 'pointer',
                    fontSize: '0.875rem',
                    color: COLORS.textPrimary,
                    borderBottom: `1px solid ${COLORS.borderLight}`,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    transition: 'all 0.2s ease-in-out',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = COLORS.backgroundLight;
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = 'transparent';
                  }}
                >
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                  </svg>
                  PDF
                </button>
                <button
                  onClick={handleExportExcel}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    textAlign: 'left',
                    border: 'none',
                    backgroundColor: 'transparent',
                    cursor: 'pointer',
                    fontSize: '0.875rem',
                    color: COLORS.textPrimary,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    transition: 'all 0.2s ease-in-out',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = COLORS.backgroundLight;
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = 'transparent';
                  }}
                >
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                  </svg>
                  Excel
                </button>
              </div>
            )}
          </div>
        </div>
        {loading && !isAssessmentSchedule && filteredSchedules.length === 0 && schedules.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '3rem', color: '#666' }}>Se încarcă...</div>
        ) : loading && isAssessmentSchedule && assessmentSchedules.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '3rem', color: '#666' }}>Se încarcă...</div>
        ) : isAssessmentSchedule ? (
          // Afișează evaluările periodice
          assessmentSchedules.length === 0 ? (
            <div
              style={{
                textAlign: 'center',
                padding: '3rem',
                backgroundColor: 'white',
                borderRadius: '8px',
                color: '#666',
              }}
            >
              Nu există evaluări periodice în sistem.
            </div>
          ) : (
            <div
              style={{
                backgroundColor: 'white',
                borderRadius: '8px',
                padding: '1.5rem',
                boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                width: '100%',
                boxSizing: 'border-box',
              }}
            >
              <h2
                style={{
                  textAlign: 'center',
                  marginBottom: '1rem',
                  color: '#000',
                  fontSize: '1rem',
                  fontWeight: '100',
                }}
              >
                {(() => {
                  const yearLabel = selectedAcademicYear === 1 ? 'I' : selectedAcademicYear === 2 ? 'II' : selectedAcademicYear === 3 ? 'III' : selectedAcademicYear === 4 ? 'IV' : selectedAcademicYear || 'I';
                  const cycleLabel = selectedCycleType === 'F' ? 'Licență - frecvență' : selectedCycleType === 'FR' ? 'Licență - frecvență redusă' : selectedCycleType === 'masterat' ? 'Masterat' : '';
                  if (selectedSemester === 'assessments1') {
                    return `Orar evaluarea periodică nr. 1 - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
                  } else if (selectedSemester === 'assessments2') {
                    return `Orar evaluarea periodică nr. 2 - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
                  } else if (selectedSemester === 'exams') {
                    return `Orar Sesiunea de examinare - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
                  }
                  return `Orar evaluarea periodică - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
                })()}
              </h2>
              <AssessmentScheduleTable
                assessmentSchedules={assessmentSchedules}
                selectedGroup={selectedGroup}
              />
            </div>
          )
        ) : loading && filteredSchedules.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '3rem', color: '#666' }}>Se încarcă...</div>
        ) : filteredSchedules.length === 0 ? (
          <div
            style={{
              textAlign: 'center',
              padding: '3rem',
              backgroundColor: 'white',
              borderRadius: '8px',
              color: '#666',
            }}
          >
            {schedules.length === 0
              ? 'Nu există orare în sistem.'
              : 'Nu există orare pentru grupul selectat.'}
          </div>
        ) : (
          <div
            style={{
              backgroundColor: 'white',
              borderRadius: '8px',
              padding: '1.5rem',
              boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
              width: '100%',
              boxSizing: 'border-box',
            }}
          >
            <h2
              style={{
                textAlign: 'center',
                marginBottom: '1rem',
                color: '#000',
                fontSize: '1rem',
                fontWeight: '100',
              }}
            >
              {(() => {
                const yearLabel = selectedAcademicYear === 1 ? 'I' : selectedAcademicYear === 2 ? 'II' : selectedAcademicYear === 3 ? 'III' : selectedAcademicYear === 4 ? 'IV' : selectedAcademicYear || 'I';
                const semesterLabel = selectedSemester === 'semester1' ? 'toamnă' : selectedSemester === 'semester2' ? 'primăvară' : '';
                const cycleLabel = selectedCycleType === 'F' ? ' - Licență frecvență' : selectedCycleType === 'FR' ? ' - Licență frecvență redusă' : selectedCycleType === 'masterat' ? ' - Masterat' : '';
                if (semesterLabel) {
                  return `Orar semestrul de ${semesterLabel} anul ${yearLabel}${cycleLabel}`;
                }
                return `Orar - Anul ${yearLabel}${cycleLabel}`;
              })()}
            </h2>
            <ScheduleTable
              schedules={filteredSchedules}
              selectedGroup={selectedGroup}
              uniqueGroups={uniqueGroups}
              dayFilter={dayFilter}
            />
          </div>
        )}
        </>
      )}
      </main>
    </div>
  );
}

