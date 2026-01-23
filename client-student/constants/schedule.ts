export const SESSION_TYPE_LABELS: Record<string, string> = {
  course: 'Curs',
  seminar: 'Seminar',
  lab: 'Laborator',
};

export const STATUS_LABELS: Record<string, string> = {
  normal: 'Normal',
  moved: 'Mutat',
  canceled: 'Anulat',
};

export const STATUS_COLORS: Record<string, string> = {
  normal: '#0f8f4b',
  moved: '#f0ad4e',
  canceled: '#d9534f',
};

// Lățimi pentru casutele tabelului de selecție orar
export const FIRST_COLUMN_WIDTH = '250px'; // Lățimea primei coloane (cu textele)
export const YEAR_COLUMN_WIDTH = '90px'; // Lățimea coloanelor cu anii și casutele goale
// Lățimea totală a tabelului numerotat: prima coloană + 4 coloane cu anii
export const TABLE_WIDTH = '710px'; // 250px + (4 × 90px) = 610px
