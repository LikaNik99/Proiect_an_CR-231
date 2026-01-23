'use client';

import React, { Fragment, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService, scheduleService, assessmentScheduleService } from '@/lib/api';
import { exportScheduleToPdf } from '@/lib/exportPdf';
import { exportScheduleToExcel } from '@/lib/exportExcel';
import { exportAssessmentScheduleToPdf } from '@/lib/exportAssessmentPdf';
import { exportAssessmentScheduleToExcel } from '@/lib/exportAssessmentExcel';
import GroupFilter from '@/components/student/GroupFilter';
import CycleFButton from '@/components/student/CycleFButton';
import CycleFRButton from '@/components/student/CycleFRButton';
import CycleMasteratButton from '@/components/student/CycleMasteratButton';
import ScheduleTable from '@/components/student/ScheduleTable';
import AssessmentScheduleTable from '@/components/student/AssessmentScheduleTable';
import { scheduleWebSocket } from '@/lib/websocket';
import { headerStyles, buttonStyles, COLORS, messageStyles } from '@/utils/styles';
import type { User } from '@/types/auth';
import type { Schedule, AssessmentSchedule } from '@/types/schedule';

const SESSION_TYPE_LABELS: Record<string, string> = {
  course: 'Curs',
  seminar: 'Seminar',
  lab: 'Laborator',
};

const STATUS_LABELS: Record<string, string> = {
  normal: 'Normal',
  moved: 'Mutat',
  canceled: 'Anulat',
};

const STATUS_COLORS: Record<string, string> = {
  normal: '#0f8f4b',
  moved: '#f0ad4e',
  canceled: '#d9534f',
};

// Lățimi pentru casutele tabelului de selecție orar
const FIRST_COLUMN_WIDTH = '250px'; // Lățimea primei coloane (cu textele)
const YEAR_COLUMN_WIDTH = '90px'; // Lățimea coloanelor cu anii și casutele goale
// Lățimea totală a tabelului numerotat: prima coloană + 4 coloane cu anii
const TABLE_WIDTH = '710px'; // 250px + (4 × 90px) = 610px

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
  const [openCycles, setOpenCycles] = useState<Set<'F' | 'FR' | 'masterat'>>(new Set()); // Set pentru a ține minte butoanele deschise
  // State pentru filtrarea schedule-urilor
  const [selectedAcademicYear, setSelectedAcademicYear] = useState<number | null>(null);
  const [selectedSemester, setSelectedSemester] = useState<string | null>(null);
  const [selectedCycleType, setSelectedCycleType] = useState<string | null>(null);
  // Ref-uri pentru valorile curente folosite în callback-ul WebSocket
  const selectedAcademicYearRef = useRef(selectedAcademicYear);
  const selectedSemesterRef = useRef(selectedSemester);
  const selectedCycleTypeRef = useRef(selectedCycleType);
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [dayFilter, setDayFilter] = useState<string | 'all'>('all');
  
  // Verifică dacă trebuie să afișăm evaluările periodice / sesiunea
  // (pentru orice an și pentru ciclurile F / FR)
  const isAssessmentSchedule =
    selectedSemester === 'assessments1' ||
    selectedSemester === 'assessments2' ||
    selectedSemester === 'exams';

  // Helper: filtrează orarele după grupa utilizatorului (nu se folosește în modul public)
  const filterSchedulesForUser = (data: Schedule[]) => {
    return data;
  };

  // Helper: filtrează evaluările după grupa utilizatorului (nu se folosește în modul public)
  const filterAssessmentsForUser = (data: AssessmentSchedule[]) => {
    return data;
  };

  // Gestionare buton "back" din browser
  useEffect(() => {
    const handlePopState = (event: PopStateEvent) => {
      // Când utilizatorul apasă "back", revenim la butoanele de ciclu
      if (showSchedule) {
        setShowSchedule(false);
        setSelectedAcademicYear(null);
        setSelectedSemester(null);
        setSelectedCycleType(null);
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

  // Inițializează starea de autentificare
  // Această pagină este DOAR pentru utilizatorii neautentificați
  useEffect(() => {
    const hasToken = authService.isAuthenticated();
    
    // Dacă nu există token, utilizatorul nu este autentificat - rămâne pe pagina publică
    if (!hasToken) {
      setIsAuthenticated(false);
      setUserEmail(null);
      setUserGroupCode(null);
      setSelectedGroup('all');
      return;
    }

    // Dacă există token, verifică dacă este valid și redirecționează la pagina autentificată
    authService
      .getCurrentUser()
      .then((user: User) => {
        // Token-ul este valid - utilizatorul este autentificat - redirecționează
        router.replace('/schedule/authenticated');
      })
      .catch((err) => {
        // Token-ul este invalid sau expirat - curăță starea și permite acces fără autentificare
        console.error('Token invalid sau expirat, se continuă fără autentificare:', err);
        authService.logout(); // Curăță token-ul invalid
        setIsAuthenticated(false);
        setUserEmail(null);
        setUserGroupCode(null);
        setSelectedGroup('all');
      });
  }, [router]);

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

        // Verifică conexiunea
        if (!isOnline) {
          setError('Nu există conexiune la internet.');
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
          const filteredData = filterSchedulesForUser(data);
          setSchedules(filteredData);
          setFilteredSchedules(filteredData);
          setError(''); // Resetează erorile la reîncărcare reușită
        } catch (err: any) {
          setError(err.response?.data?.detail || 'Eroare la încărcarea orarului.');
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
      if (
        selectedAcademicYear === null ||
        selectedSemester === null ||
        selectedCycleType === null
      ) {
        return;
      }

      if (showLoading) {
        setLoading(true);
      }

      try {
        // Verifică conexiunea
        if (!isOnline) {
          setError('Nu există conexiune la server.');
          if (showLoading) {
            setLoading(false);
          }
          return;
        }

        // Încearcă să încarce de la server
        const data = await assessmentScheduleService.getAllAssessmentSchedules({
          academic_year: selectedAcademicYear,
          semester: selectedSemester,
          cycle_type: selectedCycleType,
        });
        const filteredData = filterAssessmentsForUser(data);
        setAssessmentSchedules(filteredData);
        setError(''); // Resetează erorile la reîncărcare reușită
      } catch (err: any) {
        console.error('Eroare la încărcarea evaluărilor periodice:', err);
        setError(err.response?.data?.detail || 'Eroare la încărcarea evaluărilor periodice.');
      } finally {
        if (showLoading) {
          setLoading(false);
        }
      }
    };

    // Încărcare inițială - doar dacă există o selecție (nu încărca toate schedule-urile la start)
    // Schedule-urile vor fi încărcate când studentul selectează un an/semestru/ciclu
    if (selectedAcademicYear !== null && selectedSemester !== null && selectedCycleType !== null) {
      // Resetăm datele înainte de încărcare pentru a evita afișarea datelor vechi
      setSchedules([]);
      setFilteredSchedules([]);
      setAssessmentSchedules([]);
      setError('');
      
      // Verifică dacă trebuie să încărce evaluări periodice
      if (isAssessmentSchedule) {
        fetchAssessmentSchedules(true);
      } else {
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
        const filtered = filterSchedulesForUser(filteredByParams);
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
              const filtered = filterSchedulesForUser(data);
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

  const handleLogin = () => {
    router.push('/login');
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

  const handleExportPDF = async () => {
    if (filteredSchedules.length === 0) {
      alert('Nu există date de exportat.');
      return;
    }

    setShowExportMenu(false);

    try {
      // Calculează grupele care trebuie exportate (din schedule-urile filtrate)
      const groupsToExport = selectedGroup === 'all' 
        ? uniqueGroups 
        : [selectedGroup];
      
      // Generează titlul pentru export
      const yearLabel = selectedAcademicYear === 1 ? 'I' : selectedAcademicYear === 2 ? 'II' : selectedAcademicYear === 3 ? 'III' : selectedAcademicYear === 4 ? 'IV' : selectedAcademicYear || 'I';
      const semesterLabel = selectedSemester === 'semester1' ? 'toamnă' : selectedSemester === 'semester2' ? 'primăvară' : '';
      const cycleLabel = selectedCycleType === 'F' ? ' - Licență frecvență' : selectedCycleType === 'FR' ? ' - Licență frecvență redusă' : selectedCycleType === 'masterat' ? ' - Masterat' : '';
      const title = semesterLabel 
        ? `Orar semestrul de ${semesterLabel} anul ${yearLabel}${cycleLabel}`
        : `Orar - Anul ${yearLabel}${cycleLabel}`;
      
      await exportScheduleToPdf(schedules, groupsToExport, selectedGroup, title);
    } catch (error: any) {
      console.error('Eroare la export:', error);
      alert(error.message || 'Eroare la exportul PDF. Asigură-te că biblioteca jsPDF este instalată.');
    }
  };

  const handleExportExcel = async () => {
    if (filteredSchedules.length === 0) {
      alert('Nu există date de exportat.');
      return;
    }

    setShowExportMenu(false);

    try {
      // Calculează grupele care trebuie exportate (din schedule-urile filtrate)
      const groupsToExport = selectedGroup === 'all' 
        ? uniqueGroups 
        : [selectedGroup];
      
      await exportScheduleToExcel(schedules, groupsToExport, selectedGroup);
    } catch (error: any) {
      console.error('Eroare la export:', error);
      alert(error.message || 'Eroare la exportul Excel. Asigură-te că biblioteca xlsx este instalată.');
    }
  };

  // Funcții de export pentru evaluările periodice
  const handleExportAssessmentPDF = async () => {
    if (assessmentSchedules.length === 0) {
      alert('Nu există date de exportat.');
      return;
    }

    setShowExportMenu(false);

    try {
      // Generează titlul pentru export
      const yearLabel = selectedAcademicYear === 1 ? 'I' : selectedAcademicYear === 2 ? 'II' : selectedAcademicYear === 3 ? 'III' : selectedAcademicYear === 4 ? 'IV' : selectedAcademicYear || 'I';
      const cycleLabel = selectedCycleType === 'F' ? 'Licență - frecvență' : selectedCycleType === 'FR' ? 'Licență - frecvență redusă' : selectedCycleType === 'masterat' ? 'Masterat' : '';
      let title = '';
      if (selectedSemester === 'assessments1') {
        title = `Orar evaluarea periodică nr. 1 - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      } else if (selectedSemester === 'assessments2') {
        title = `Orar evaluarea periodică nr. 2 - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      } else if (selectedSemester === 'exams') {
        title = `Orar Sesiunea de examinare - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      } else {
        title = `Orar evaluarea periodică - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      }
      
      await exportAssessmentScheduleToPdf(assessmentSchedules, selectedGroup, title);
    } catch (error: any) {
      console.error('Eroare la export:', error);
      alert(error.message || 'Eroare la exportul PDF. Asigură-te că biblioteca jsPDF este instalată.');
    }
  };

  const handleExportAssessmentExcel = async () => {
    if (assessmentSchedules.length === 0) {
      alert('Nu există date de exportat.');
      return;
    }

    setShowExportMenu(false);

    try {
      // Generează titlul pentru export
      const yearLabel = selectedAcademicYear === 1 ? 'I' : selectedAcademicYear === 2 ? 'II' : selectedAcademicYear === 3 ? 'III' : selectedAcademicYear === 4 ? 'IV' : selectedAcademicYear || 'I';
      const cycleLabel = selectedCycleType === 'F' ? 'Licență - frecvență' : selectedCycleType === 'FR' ? 'Licență - frecvență redusă' : selectedCycleType === 'masterat' ? 'Masterat' : '';
      let title = '';
      if (selectedSemester === 'assessments1') {
        title = `Orar evaluarea periodică nr. 1 - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      } else if (selectedSemester === 'assessments2') {
        title = `Orar evaluarea periodică nr. 2 - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      } else if (selectedSemester === 'exams') {
        title = `Orar Sesiunea de examinare - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      } else {
        title = `Orar evaluarea periodică - Anul ${yearLabel}${cycleLabel ? ` - ${cycleLabel}` : ''}`;
      }
      
      await exportAssessmentScheduleToExcel(assessmentSchedules, selectedGroup, title);
    } catch (error: any) {
      console.error('Eroare la export:', error);
      alert(error.message || 'Eroare la exportul Excel. Asigură-te că biblioteca xlsx este instalată.');
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
          <button
            onClick={handleLogin}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = COLORS.darkHover;
              e.currentTarget.style.boxShadow = COLORS.shadow;
              e.currentTarget.style.transform = 'translateY(-1px)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = COLORS.dark;
              e.currentTarget.style.boxShadow = COLORS.shadowSm;
              e.currentTarget.style.transform = 'translateY(0)';
            }}
            style={{
              ...buttonStyles.dark,
            }}
          >
            Autentificare
          </button>
        </div>
      </header>

      <main style={{ padding: '2rem', maxWidth: '1400px', margin: '0 auto' }}>
        {error && (
          <div style={messageStyles.error}>
            {error}
          </div>
        )}

        {/* Container cu butoane pentru selectarea orarului - DOAR pentru utilizatorii neautentificați */}
        {!showSchedule && (
          <div
            style={{
              backgroundColor: 'white',
              borderRadius: '8px',
              boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
              overflow: 'hidden',
              padding: '2rem',
              width: TABLE_WIDTH,
              margin: '0 auto',
            }}
          >
            <table
              style={{
                width: '100%',
                borderCollapse: 'collapse',
              }}
            >
              <tbody>
                <CycleFButton
                  isOpen={openCycles.has('F')}
                  onToggle={() => {
                    setOpenCycles((prev) => {
                      const newSet = new Set(prev);
                      if (newSet.has('F')) {
                        newSet.delete('F');
                      } else {
                        newSet.add('F');
                      }
                      return newSet;
                    });
                  }}
                  onScheduleSelect={(year, period, cellNumber) => {
                    // Setează valorile pentru filtrare
                    setSelectedGroup('all');
                    setDayFilter('all');
                    setSelectedAcademicYear(year);
                    setSelectedSemester(period);
                    setSelectedCycleType('F');
                    setShowSchedule(true);
                    // Adaugă o intrare în istoricul browser-ului pentru a permite butonul "back"
                    window.history.pushState({ showSchedule: true }, '', window.location.href);
                    // fetchSchedules va fi apelat automat prin useEffect când state-urile se actualizează
                  }}
                />
                <CycleFRButton
                  isOpen={openCycles.has('FR')}
                  onToggle={() => {
                    setOpenCycles((prev) => {
                      const newSet = new Set(prev);
                      if (newSet.has('FR')) {
                        newSet.delete('FR');
                      } else {
                        newSet.add('FR');
                      }
                      return newSet;
                    });
                  }}
                  onScheduleSelect={(year, period, cellNumber) => {
                    // Setează valorile pentru filtrare
                    setSelectedGroup('all');
                    setDayFilter('all');
                    setSelectedAcademicYear(year);
                    setSelectedSemester(period);
                    setSelectedCycleType('FR');
                    setShowSchedule(true);
                    // Adaugă o intrare în istoricul browser-ului pentru a permite butonul "back"
                    window.history.pushState({ showSchedule: true }, '', window.location.href);
                    // fetchSchedules va fi apelat automat prin useEffect când state-urile se actualizează
                  }}
                />
                <CycleMasteratButton
                  isOpen={openCycles.has('masterat')}
                  onToggle={() => {
                    setOpenCycles((prev) => {
                      const newSet = new Set(prev);
                      if (newSet.has('masterat')) {
                        newSet.delete('masterat');
                      } else {
                        newSet.add('masterat');
                      }
                      return newSet;
                    });
                  }}
                />
              </tbody>
            </table>
          </div>
        )}

        {/* Orarul - se afișează doar când showSchedule este true */}
        {showSchedule && (
          <>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', width: '100%', marginBottom: '1rem', marginTop: '0', position: 'relative' }}>
          {/* Filtrare pe grupe - doar pentru utilizatorii neautentificați */}
          <GroupFilter
            groups={uniqueGroups}
            selectedGroup={selectedGroup}
            onGroupSelect={setSelectedGroup}
          />
          
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
                  onClick={isAssessmentSchedule ? handleExportAssessmentPDF : handleExportPDF}
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
                  onClick={isAssessmentSchedule ? handleExportAssessmentExcel : handleExportExcel}
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
        {loading ? (
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

