import { pool } from '../config/database.js';

async function addListColorColumn() {
  try {
    console.log('🔄 Adding color column to lists table...');
    
    // Check if column exists first
    const [columns] = await pool.query(`
      SHOW COLUMNS FROM lists LIKE 'color'
    `);
    
    if (columns.length === 0) {
      // Column doesn't exist, add it
      await pool.query(`
        ALTER TABLE lists 
        ADD COLUMN color VARCHAR(50) DEFAULT 'default' AFTER position
      `);
      console.log('✅ Color column added to lists table successfully!');
    } else {
      console.log('ℹ️  Color column already exists in lists table');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error adding color column:', error);
    process.exit(1);
  }
}

addListColorColumn();
