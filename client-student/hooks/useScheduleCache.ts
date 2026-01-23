import type { Schedule, AssessmentSchedule } from '@/types/schedule';

const SCHEDULE_PREFS_KEY = 'schedule_prefs';

/**
 * Generează cheia de cache pentru datele de orar
 */
export const getCacheKey = (
  userGroupCode: string | null,
  academicYear: number | null,
  semester: string | null,
  cycleType: string | null,
  isAssessment: boolean
): string | null => {
  if (!academicYear || !semester || !cycleType) return null;
  const prefix = isAssessment ? 'assessment_schedules' : 'schedules';
  return `${prefix}_${userGroupCode || 'all'}_${academicYear}_${semester}_${cycleType}`;
};

/**
 * Salvează datele în cache
 */
export const saveToCache = (
  userGroupCode: string | null,
  academicYear: number | null,
  semester: string | null,
  cycleType: string | null,
  isAssessment: boolean,
  data: Schedule[] | AssessmentSchedule[]
): void => {
  if (typeof window === 'undefined') return;
  
  const cacheKey = getCacheKey(userGroupCode, academicYear, semester, cycleType, isAssessment);
  if (!cacheKey) return;

  try {
    const cacheData = {
      data,
      timestamp: Date.now(),
      academicYear,
      semester,
      cycleType,
    };
    localStorage.setItem(cacheKey, JSON.stringify(cacheData));
  } catch (error) {
    console.warn('[Cache] Eroare la salvarea în cache:', error);
  }
};

/**
 * Încarcă datele din cache
 */
export const loadFromCache = (
  userGroupCode: string | null,
  academicYear: number | null,
  semester: string | null,
  cycleType: string | null,
  isAssessment: boolean
): Schedule[] | AssessmentSchedule[] | null => {
  if (typeof window === 'undefined') return null;
  
  const cacheKey = getCacheKey(userGroupCode, academicYear, semester, cycleType, isAssessment);
  if (!cacheKey) return null;

  try {
    const cached = localStorage.getItem(cacheKey);
    if (!cached) return null;

    const cacheData = JSON.parse(cached);
    
    // Verifică dacă datele din cache sunt pentru aceeași combinație
    if (
      cacheData.academicYear === academicYear &&
      cacheData.semester === semester &&
      cacheData.cycleType === cycleType
    ) {
      return cacheData.data;
    }
  } catch (error) {
    console.warn('[Cache] Eroare la încărcarea din cache:', error);
  }

  return null;
};

/**
 * Salvează preferințele orarului (an, semestru, ciclu)
 */
export const saveSchedulePrefs = (
  userGroupCode: string | null,
  academicYear: number | null,
  semester: string | null,
  cycleType: string | null
): void => {
  if (typeof window === 'undefined') return;
  const key = `${SCHEDULE_PREFS_KEY}_${userGroupCode || 'all'}`;
  try {
    localStorage.setItem(key, JSON.stringify({
      academicYear: academicYear ?? 1,
      semester: semester ?? 'semester1',
      cycleType: cycleType ?? 'F',
    }));
  } catch (e) {
    console.warn('[Cache] Eroare la salvarea preferințelor:', e);
  }
};

/**
 * Încarcă preferințele orarului (an, semestru, ciclu)
 */
export const loadSchedulePrefs = (
  userGroupCode: string | null,
  groupCode?: string | null
): { academicYear: number; semester: string; cycleType: string } | null => {
  if (typeof window === 'undefined') return null;
  const key = `${SCHEDULE_PREFS_KEY}_${groupCode ?? userGroupCode ?? 'all'}`;
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    const p = JSON.parse(raw);
    if (p && typeof p.academicYear === 'number' && p.semester && p.cycleType) {
      return { academicYear: p.academicYear, semester: p.semester, cycleType: p.cycleType };
    }
  } catch (e) {
    console.warn('[Cache] Eroare la încărcarea preferințelor:', e);
  }
  return null;
};

/**
 * Șterge cache-ul pentru un utilizator
 */
export const clearUserCache = (userGroupCode: string | null): void => {
  if (typeof window === 'undefined') return;
  
  try {
    const keysToRemove: string[] = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && (key.startsWith('schedules_') || key.startsWith('assessment_schedules_') || key.startsWith('schedule_prefs_'))) {
        if (!userGroupCode || key.includes(`_${userGroupCode}_`) || key.includes(`_${userGroupCode}`)) {
          keysToRemove.push(key);
        }
      }
    }
    keysToRemove.forEach(key => localStorage.removeItem(key));
  } catch (error) {
    console.warn('[Cache] Eroare la ștergerea cache-ului:', error);
  }
};
