import { exportScheduleToPdf } from '@/lib/exportPdf';
import { exportScheduleToExcel } from '@/lib/exportExcel';
import { exportAssessmentScheduleToPdf } from '@/lib/exportAssessmentPdf';
import { exportAssessmentScheduleToExcel } from '@/lib/exportAssessmentExcel';
import type { Schedule, AssessmentSchedule } from '@/types/schedule';

interface UseScheduleExportParams {
  schedules: Schedule[];
  filteredSchedules: Schedule[];
  assessmentSchedules: AssessmentSchedule[];
  selectedGroup: string;
  uniqueGroups: string[];
  selectedAcademicYear: number | null;
  selectedSemester: string | null;
  selectedCycleType: string | null;
  isAssessmentSchedule: boolean;
  onExportMenuClose: () => void;
}

/**
 * Hook pentru gestionarea exportului de orare
 */
export const useScheduleExport = ({
  schedules,
  assessmentSchedules,
  selectedGroup,
  uniqueGroups,
  selectedAcademicYear,
  selectedSemester,
  selectedCycleType,
  isAssessmentSchedule,
  onExportMenuClose,
}: UseScheduleExportParams) => {
  const handleExportPDF = async () => {
    if (isAssessmentSchedule) {
      if (assessmentSchedules.length === 0) {
        alert('Nu există date de exportat.');
        return;
      }

      onExportMenuClose();

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
    } else {
      if (filteredSchedules.length === 0) {
        alert('Nu există date de exportat.');
        return;
      }

      onExportMenuClose();

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
    }
  };

  const handleExportExcel = async () => {
    if (isAssessmentSchedule) {
      if (assessmentSchedules.length === 0) {
        alert('Nu există date de exportat.');
        return;
      }

      onExportMenuClose();

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
    } else {
      if (filteredSchedules.length === 0) {
        alert('Nu există date de exportat.');
        return;
      }

      onExportMenuClose();

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
        
        await exportScheduleToExcel(schedules, groupsToExport, selectedGroup, title);
      } catch (error: any) {
        console.error('Eroare la export:', error);
        alert(error.message || 'Eroare la exportul Excel. Asigură-te că biblioteca xlsx este instalată.');
      }
    }
  };

  return {
    handleExportPDF,
    handleExportExcel,
  };
};
