import type { AssessmentSchedule } from '@/types/schedule';

/**
 * Escapare HTML pentru a preveni XSS
 */
function escapeHtml(text: string): string {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * Exportează evaluările periodice în format PDF
 * @param assessmentSchedules - Lista de evaluări periodice de exportat
 * @param selectedGroup - Grupa selectată ('all' pentru toate grupele)
 * @param title - Titlul documentului (ex: "Orar evaluarea periodică nr. 1")
 */
export const exportAssessmentScheduleToPdf = async (
  assessmentSchedules: AssessmentSchedule[],
  selectedGroup: string = 'all',
  title: string = 'Evaluări periodice'
): Promise<void> => {
  try {
    // Import dinamic jsPDF și html2canvas pentru a evita probleme de SSR
    const jsPDFModule = await import('jspdf');
    const jsPDF = jsPDFModule.default || jsPDFModule.jsPDF;
    const html2canvas = (await import('html2canvas')).default;

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

    // Dimensiuni pagină A4 portrait: 210mm x 297mm
    const pageWidth = 210;
    const pageHeight = 297;

    // Creăm un div temporar cu tabelul HTML
    const tempDiv = document.createElement('div');
    tempDiv.style.position = 'absolute';
    tempDiv.style.left = '-9999px';
    tempDiv.style.width = `${pageWidth - 20}mm`;
    tempDiv.style.backgroundColor = 'white';
    tempDiv.style.padding = '10mm';
    tempDiv.style.fontFamily = 'Arial, sans-serif';
    tempDiv.style.color = '#000000';

    // Generează HTML-ul tabelului
    let tableHTML = `
      <h2 style="margin: 0 0 5px 0; font-size: 14pt; font-weight: bold; color: #000000;">${escapeHtml(title)}</h2>
      <p style="margin: 0 0 10px 0; font-size: 10pt; color: #000000;">${selectedGroup === 'all' ? 'Toate grupele' : `Grupă: ${selectedGroup}`}</p>
      <table style="width: 100%; border-collapse: collapse; font-size: 8pt; border: 1px solid #000; color: #000000;">
        <thead>
          <tr>
            <th style="border: 1px solid #000; padding: 4px; background-color: #f0f0f0; font-weight: bold; text-align: left; color: #000000;">Disciplina</th>
            <th style="border: 1px solid #000; padding: 4px; background-color: #f0f0f0; font-weight: bold; text-align: left; color: #000000;">Componența seriei</th>
            <th style="border: 1px solid #000; padding: 4px; background-color: #f0f0f0; font-weight: bold; text-align: left; color: #000000;">Cadrul didactic</th>
            <th style="border: 1px solid #000; padding: 4px; background-color: #f0f0f0; font-weight: bold; text-align: center; color: #000000;">Data</th>
            <th style="border: 1px solid #000; padding: 4px; background-color: #f0f0f0; font-weight: bold; text-align: center; color: #000000;">Ora</th>
            <th style="border: 1px solid #000; padding: 4px; background-color: #f0f0f0; font-weight: bold; text-align: center; color: #000000;">Sala</th>
          </tr>
        </thead>
        <tbody>
    `;

    // Adaugă rândurile pentru fiecare disciplină
    for (const [subject, assessments] of assessmentsBySubject.entries()) {
      assessments.forEach((assessment, index) => {
        tableHTML += '<tr>';
        
        // Disciplina (doar pentru primul rând al fiecărei discipline)
        if (index === 0) {
          tableHTML += `<td rowspan="${assessments.length}" style="border: 1px solid #000; padding: 4px; text-align: left; font-weight: bold; vertical-align: middle; color: #000000; background-color: #f9fafb;">${escapeHtml(subject)}</td>`;
        }
        
        // Componența seriei
        const groupsDisplay = selectedGroup === 'all'
          ? assessment.groups_composition
          : assessment.groups_composition
              .split(',')
              .map((g) => g.trim())
              .filter((g) => g === selectedGroup)
              .join(', ');
        tableHTML += `<td style="border: 1px solid #000; padding: 4px; text-align: left; color: #000000;">${escapeHtml(groupsDisplay)}</td>`;
        
        // Cadrul didactic
        tableHTML += `<td style="border: 1px solid #000; padding: 4px; text-align: left; color: #000000;">${escapeHtml(assessment.professor_name)}</td>`;
        
        // Data
        tableHTML += `<td style="border: 1px solid #000; padding: 4px; text-align: center; color: #000000;">${escapeHtml(assessment.assessment_date)}</td>`;
        
        // Ora
        tableHTML += `<td style="border: 1px solid #000; padding: 4px; text-align: center; color: #000000;">${escapeHtml(assessment.assessment_time)}</td>`;
        
        // Sala
        tableHTML += `<td style="border: 1px solid #000; padding: 4px; text-align: center; color: #000000; font-weight: bold;">${escapeHtml(assessment.room_code)}</td>`;
        
        tableHTML += '</tr>';
      });
    }

    const now = new Date();
    const dateStr = now.toLocaleDateString('ro-RO');
    const timeStr = now.toLocaleTimeString('ro-RO', { hour: '2-digit', minute: '2-digit' });
    
    tableHTML += `
        </tbody>
      </table>
      <p style="margin-top: 5px; font-size: 7pt; color: #000000;">Exportat la: ${dateStr} ${timeStr}</p>
    `;

    tempDiv.innerHTML = tableHTML;
    document.body.appendChild(tempDiv);

    // Capturează tabelul ca imagine
    const canvas = await html2canvas(tempDiv, {
      scale: 2,
      useCORS: true,
      backgroundColor: '#ffffff',
      logging: false,
    });

    // Elimină elementul temporar
    document.body.removeChild(tempDiv);

    // Calculează dimensiunile pentru a se încadra pe pagină
    const imgWidth = pageWidth - 20; // 10mm margine pe fiecare parte
    const imgHeight = (canvas.height * imgWidth) / canvas.width;
    
    // Dacă înălțimea depășește pagina, redimensionăm
    let finalHeight = imgHeight;
    let finalWidth = imgWidth;
    if (finalHeight > pageHeight - 20) {
      finalHeight = pageHeight - 20;
      finalWidth = (canvas.width * finalHeight) / canvas.height;
    }

    // Creează PDF-ul cu imaginea
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4',
    });

    // Adaugă imaginea în PDF
    const imgData = canvas.toDataURL('image/jpeg', 0.95);
    doc.addImage(imgData, 'JPEG', 10, 10, finalWidth, finalHeight);

    // Salvează PDF-ul
    const fileName = `evaluari-periodice-${selectedGroup === 'all' ? 'toate-grupele' : selectedGroup}-${dateStr.replace(/\//g, '-')}.pdf`;
    
    doc.save(fileName);
  } catch (error) {
    console.error('Eroare la exportul PDF pentru evaluări periodice:', error);
    throw error;
  }
};
