import type { Schedule, AssessmentSchedule } from '@/types/schedule';

/**
 * Filtrează orarele după grupa utilizatorului
 */
export const filterSchedulesForUser = (data: Schedule[], userGroupCode: string | null): Schedule[] => {
  if (userGroupCode) {
    return data.filter((s) => s.group.code === userGroupCode);
  }
  return data;
};

/**
 * Filtrează evaluările după grupa utilizatorului
 */
export const filterAssessmentsForUser = (data: AssessmentSchedule[], userGroupCode: string | null): AssessmentSchedule[] => {
  if (userGroupCode) {
    return data
      .filter((a) =>
        a.groups_composition
          .split(',')
          .map((g) => g.trim())
          .includes(userGroupCode)
      )
      .map((a) => ({
        ...a,
        groups_composition: userGroupCode, // Modifică groups_composition să afișeze doar grupa utilizatorului
      }));
  }
  return data;
};
