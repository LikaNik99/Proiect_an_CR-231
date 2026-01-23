import type { AssessmentSchedule } from '@/types/schedule';

/**
 * Exportează evaluările periodice în format Excel
 * @param assessmentSchedules - Lista de evaluări periodice de exportat
 * @param selectedGroup - Grupa selectată ('all' pentru toate grupele)
 * @param title - Titlul documentului (ex: "Orar evaluarea periodică nr. 1")
 */
export const exportAssessmentScheduleToExcel = async (
  assessmentSchedules: AssessmentSchedule[],
  selectedGroup: string = 'all',
  title: string = 'Evaluări periodice'
): Promise<void> => {
  try {
    // Import dinamic exceljs pentru a evita probleme de SSR
    const ExcelJS = (await import('exceljs')).default;

    // Filtrează evaluările după grup dacă este selectat un grup specific
    const filteredAssessments =
      selectedGroup === 'all'
        ? assessmentSchedules
        : assessmentSchedules.filter((assessment) => {
            const groups = assessment.groups_composition
              .split(',')
              .map((g) => g.trim())
              .filter((g) => g.length > 0);
            return groups.includes(selectedGroup);
          });

    // Sortăm evaluările după disciplină, apoi după dată și oră
    const sortedAssessments = [...filteredAssessments].sort((a, b) => {
      const subjectComparison = a.subject.localeCompare(b.subject);
      if (subjectComparison !== 0) return subjectComparison;
      const dateComparison = a.assessment_date.localeCompare(b.assessment_date);
      if (dateComparison !== 0) return dateComparison;
      return a.assessment_time.localeCompare(b.assessment_time);
    });

    // Grupează evaluările după disciplină
    const assessmentsBySubject = new Map<string, AssessmentSchedule[]>();
    sortedAssessments.forEach((assessment) => {
      const subject = assessment.subject;
      if (!assessmentsBySubject.has(subject)) {
        assessmentsBySubject.set(subject, []);
      }
      assessmentsBySubject.get(subject)!.push(assessment);
    });

    // Creează workbook-ul Excel
    const workbook = new ExcelJS.Workbook();
    const sheetName = title.length > 31 ? title.substring(0, 28) + '...' : title; // Excel limitează numele la 31 caractere
    const worksheet = workbook.addWorksheet(sheetName);

    // Setează lățimile coloanelor
    worksheet.getColumn(1).width = 30; // Disciplina
    worksheet.getColumn(2).width = 25; // Componența seriei
    worksheet.getColumn(3).width = 30; // Cadrul didactic
    worksheet.getColumn(4).width = 12; // Data
    worksheet.getColumn(5).width = 12; // Ora
    worksheet.getColumn(6).width = 10; // Sala

    // Adaugă titlul
    const titleRow = worksheet.addRow([title]);
    titleRow.font = { bold: true, size: 14 };
    titleRow.alignment = { horizontal: 'center', vertical: 'middle' };
    worksheet.mergeCells(1, 1, 1, 6);

    // Adaugă subtitlul (grupă)
    const subtitleRow = worksheet.addRow([selectedGroup === 'all' ? 'Toate grupele' : `Grupă: ${selectedGroup}`]);
    subtitleRow.font = { size: 11 };
    subtitleRow.alignment = { horizontal: 'center', vertical: 'middle' };
    worksheet.mergeCells(2, 1, 2, 6);

    // Rând gol
    worksheet.addRow([]);

    // Header-ul tabelului
    const headerRow = worksheet.addRow([
      'Disciplina',
      'Componența seriei',
      'Cadrul didactic titular',
      'Data',
      'Ora',
      'Sala',
    ]);
    headerRow.font = { bold: true };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFF0F0F0' },
    };
    headerRow.alignment = { horizontal: 'center', vertical: 'middle' };
    headerRow.height = 25;

    // Adaugă border-uri pentru header
    headerRow.eachCell({ includeEmpty: true }, (cell) => {
      cell.border = {
        top: { style: 'thin' },
        left: { style: 'thin' },
        bottom: { style: 'thin' },
        right: { style: 'thin' },
      };
    });

    // Adaugă datele
    let currentRowIndex = 4; // După titlu, subtitlu și header
    const mergeCellsInfo: Array<{ startRow: number; endRow: number; subject: string }> = [];

    for (const [subject, assessments] of assessmentsBySubject.entries()) {
      const subjectStartRow = currentRowIndex;

      assessments.forEach((assessment) => {
        const row = worksheet.addRow([]);

        // Disciplina (doar pentru primul rând al fiecărei discipline)
        if (assessments.indexOf(assessment) === 0) {
          const subjectCell = row.getCell(1);
          subjectCell.value = subject;
          subjectCell.font = { bold: true };
          subjectCell.alignment = { horizontal: 'left', vertical: 'middle', wrapText: true };
          subjectCell.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFF9FAFB' },
          };
        }

        // Componența seriei
        const groupsDisplay = selectedGroup === 'all'
          ? assessment.groups_composition
          : assessment.groups_composition
              .split(',')
              .map((g) => g.trim())
              .filter((g) => g === selectedGroup)
              .join(', ');
        const groupsCell = row.getCell(2);
        groupsCell.value = groupsDisplay;
        groupsCell.alignment = { horizontal: 'left', vertical: 'middle', wrapText: true };

        // Cadrul didactic
        const professorCell = row.getCell(3);
        professorCell.value = assessment.professor_name;
        professorCell.alignment = { horizontal: 'left', vertical: 'middle', wrapText: true };

        // Data
        const dateCell = row.getCell(4);
        dateCell.value = assessment.assessment_date;
        dateCell.alignment = { horizontal: 'center', vertical: 'middle' };

        // Ora
        const timeCell = row.getCell(5);
        timeCell.value = assessment.assessment_time;
        timeCell.alignment = { horizontal: 'center', vertical: 'middle' };

        // Sala
        const roomCell = row.getCell(6);
        roomCell.value = assessment.room_code;
        roomCell.alignment = { horizontal: 'center', vertical: 'middle' };
        roomCell.font = { bold: true };

        // Adaugă border-uri pentru toate celulele
        row.eachCell({ includeEmpty: false }, (cell) => {
          cell.border = {
            top: { style: 'thin' },
            left: { style: 'thin' },
            bottom: { style: 'thin' },
            right: { style: 'thin' },
          };
        });

        currentRowIndex++;
      });

      // Salvează informațiile pentru merge cells (se face după ce toate rândurile sunt create)
      if (assessments.length > 1) {
        mergeCellsInfo.push({
          startRow: subjectStartRow,
          endRow: currentRowIndex - 1,
          subject: subject,
        });
      }
    }

    // Face merge cells pentru discipline după ce toate rândurile sunt create
    for (const mergeInfo of mergeCellsInfo) {
      // Șterge valorile din celulele care vor fi merged (pentru a evita conflicte)
      for (let row = mergeInfo.startRow + 1; row <= mergeInfo.endRow; row++) {
        const cell = worksheet.getCell(row, 1);
        cell.value = null;
      }
      
      // Face merge
      worksheet.mergeCells(mergeInfo.startRow, 1, mergeInfo.endRow, 1);
      
      // Reaplică formatarea pentru celula merged
      const subjectCell = worksheet.getCell(mergeInfo.startRow, 1);
      subjectCell.value = mergeInfo.subject;
      subjectCell.font = { bold: true };
      subjectCell.alignment = { horizontal: 'left', vertical: 'middle', wrapText: true };
      subjectCell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFF9FAFB' },
      };
      subjectCell.border = {
        top: { style: 'thin' },
        left: { style: 'thin' },
        bottom: { style: 'thin' },
        right: { style: 'thin' },
      };
    }

    // Setează înălțimea rândurilor
    for (let row = 4; row < currentRowIndex; row++) {
      worksheet.getRow(row).height = 25;
    }

    // Generează data pentru numele fișierului
    const now = new Date();
    const dateStr = now.toLocaleDateString('ro-RO').replace(/\//g, '-');
    
    // Nume fișier
    const fileName = `evaluari-periodice-${selectedGroup === 'all' ? 'toate-grupele' : selectedGroup}-${dateStr}.xlsx`;

    // Exportă fișierul Excel
    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], { 
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
    });
    
    // Creează link de download
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);

  } catch (error) {
    console.error('Eroare la exportul Excel pentru evaluări periodice:', error);
    throw error;
  }
};
