-- ===========================================
-- TWEETS APP - STRUCTURA AVANSATĂ
-- Suport thread-uri, tag-uri, utilizatori
-- ===========================================

CREATE DATABASE IF NOT EXISTS tweets_advanced;
USE tweets_advanced;

-- 1. Tabel utilizatori (extins)
CREATE TABLE users (
                       user_id INT PRIMARY KEY AUTO_INCREMENT,
                       username VARCHAR(50) UNIQUE NOT NULL,
                       password VARCHAR(100) NOT NULL,
                       email VARCHAR(100) NOT NULL UNIQUE,
                       full_name VARCHAR(100),
                       bio TEXT,
                       avatar_color VARCHAR(7) DEFAULT '#3498db',
                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                       last_login TIMESTAMP NULL,
                       is_active BOOLEAN DEFAULT TRUE,
                       role ENUM('user', 'moderator', 'admin') DEFAULT 'user',
                       INDEX idx_username (username),
                       INDEX idx_email (email),
                       INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Tabel thread-uri (postări principale)
CREATE TABLE threads (
                         thread_id INT PRIMARY KEY AUTO_INCREMENT,
                         user_id INT NOT NULL,
                         title VARCHAR(200) NOT NULL,
                         content TEXT NOT NULL,
                         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
                         is_locked BOOLEAN DEFAULT FALSE,
                         is_pinned BOOLEAN DEFAULT FALSE,
                         view_count INT DEFAULT 0,
                         vote_score INT DEFAULT 0,
                         FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
                         INDEX idx_user_id (user_id),
                         INDEX idx_created_at (created_at),
                         INDEX idx_is_pinned (is_pinned),
                         FULLTEXT idx_search (title, content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Tabel tag-uri
CREATE TABLE tags (
                      tag_id INT PRIMARY KEY AUTO_INCREMENT,
                      name VARCHAR(50) UNIQUE NOT NULL,
                      color VARCHAR(7) DEFAULT '#95a5a6',
                      description TEXT,
                      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                      INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Tabel asociere thread-tag
CREATE TABLE thread_tags (
                             thread_id INT NOT NULL,
                             tag_id INT NOT NULL,
                             PRIMARY KEY (thread_id, tag_id),
                             FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON DELETE CASCADE,
                             FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE,
                             INDEX idx_tag_id (tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Tabel comentarii (răspunsuri în thread)
CREATE TABLE comments (
                          comment_id INT PRIMARY KEY AUTO_INCREMENT,
                          thread_id INT NOT NULL,
                          user_id INT NOT NULL,
                          parent_comment_id INT NULL,
                          content TEXT NOT NULL,
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
                          vote_score INT DEFAULT 0,
                          is_edited BOOLEAN DEFAULT FALSE,
                          FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON DELETE CASCADE,
                          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
                          FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE,
                          INDEX idx_thread_id (thread_id),
                          INDEX idx_user_id (user_id),
                          INDEX idx_parent_comment (parent_comment_id),
                          INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Tabel voturi (upvote/downvote)
CREATE TABLE votes (
                       vote_id INT PRIMARY KEY AUTO_INCREMENT,
                       user_id INT NOT NULL,
                       thread_id INT NULL,
                       comment_id INT NULL,
                       vote_type ENUM('upvote', 'downvote') NOT NULL,
                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                       UNIQUE KEY unique_vote (user_id, thread_id, comment_id),
                       FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
                       FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON DELETE CASCADE,
                       FOREIGN KEY (comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE,
                       INDEX idx_user_votes (user_id),
                       INDEX idx_thread_votes (thread_id),
                       INDEX idx_comment_votes (comment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Tabel utilizatori activi (pentru afișare online)
CREATE TABLE active_users (
                              session_id VARCHAR(100) PRIMARY KEY,
                              user_id INT NOT NULL,
                              thread_id INT NULL,
                              last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                              ip_address VARCHAR(45),
                              FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
                              FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON DELETE SET NULL,
                              INDEX idx_user_active (user_id),
                              INDEX idx_thread_active (thread_id),
                              INDEX idx_last_activity (last_activity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Tabel mesaje private (opțional pentru viitor)
CREATE TABLE private_messages (
                                  message_id INT PRIMARY KEY AUTO_INCREMENT,
                                  sender_id INT NOT NULL,
                                  receiver_id INT NOT NULL,
                                  content TEXT NOT NULL,
                                  is_read BOOLEAN DEFAULT FALSE,
                                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
                                  FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE,
                                  INDEX idx_sender (sender_id),
                                  INDEX idx_receiver (receiver_id),
                                  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================================
-- DATE DEMO
-- ===========================================

-- Tag-uri predefinite
INSERT INTO tags (name, color, description) VALUES
                                                ('tehnologie', '#3498db', 'Discuții despre tehnologie și IT'),
                                                ('educație', '#2ecc71', 'Învățare și resurse educaționale'),
                                                ('programare', '#e74c3c', 'Discuții despre programare'),
                                                ('java', '#f39c12', 'Java și tehnologii Java'),
                                                ('UTM', '#9b59b6', 'Universitatea Tehnică a Moldovei'),
                                                ('proiecte', '#1abc9c', 'Proiecte și colaborări'),
                                                ('întrebări', '#34495e', 'Întrebări și ajutor'),
                                                ('știri', '#e67e22', 'Știri și evenimente');

-- Utilizatori demo
INSERT INTO users (username, password, email, full_name, bio, avatar_color, role) VALUES
                                                                                      ('student', 'student123', 'student@utm.md', 'Ion Popescu', 'Student la UTM, interesat de programare', '#3498db', 'user'),
                                                                                      ('profesor', 'prof123', 'profesor@utm.md', 'Dr. Maria Ionescu', 'Profesor universitar, specializare rețele', '#2ecc71', 'moderator'),
                                                                                      ('admin', 'admin123', 'admin@utm.md', 'Administrator Sistem', 'Administrator al platformei', '#e74c3c', 'admin'),
                                                                                      ('dev_pavel', 'pavel123', 'buga.pavel@utm.md', 'Buga Pavel', 'Dezvoltator aplicație, CR-231', '#9b59b6', 'user'),
                                                                                      ('test_user', 'test123', 'test@example.com', 'Utilizator Test', 'Cont pentru testare', '#f39c12', 'user');

-- Thread-uri demo
INSERT INTO threads (user_id, title, content, is_pinned, view_count, vote_score) VALUES
                                                                                     (1, 'Cum să învăț Java mai eficient?', 'Salut! Sunt nou în programare și aș dori să știu ce resurse recomandați pentru a învăța Java. Am început cu un curs online, dar aș vrea să aprofundez.', FALSE, 150, 12),
                                                                                     (2, 'Proiecte pentru studenți - Colaborare', 'Organizez o echipă pentru dezvoltarea unui proiect open-source. Caut studenți pasionați de backend development.', FALSE, 89, 8),
                                                                                     (3, 'Reguli platformă și ghid de utilizare', 'Vă rugăm să citiți acest ghid înainte de a posta. Respectați regulile comunității.', TRUE, 320, 25),
                                                                                     (4, 'Tweets App - Aplicație Client-Server', 'Am dezvoltat această aplicație ca proiect pentru facultate. Sursa este disponibilă pe GitHub. Feedback welcome!', FALSE, 210, 18),
                                                                                     (1, 'Probleme cu conexiunea la baza de date', 'Am o problemă cu conectarea aplicației mele Java la MySQL. Cine mă poate ajuta?', FALSE, 75, 3);

-- Asocieri thread-tag
INSERT INTO thread_tags (thread_id, tag_id) VALUES
                                                (1, 3), (1, 4), (1, 2),  -- Java, Programare, Educație
                                                (2, 6), (2, 3),         -- Proiecte, Programare
                                                (3, 2), (3, 5),         -- Educație, UTM
                                                (4, 3), (4, 4), (4, 5), -- Programare, Java, UTM
                                                (5, 1), (5, 3), (5, 7); -- Tehnologie, Programare, Întrebări

-- Comentarii demo
INSERT INTO comments (thread_id, user_id, parent_comment_id, content, vote_score) VALUES
                                                                                      (1, 2, NULL, 'Recomand cărțile "Effective Java" și "Head First Java". Sunt excelente pentru începători!', 5),
                                                                                      (1, 4, NULL, 'Urmărește tutorialele de pe YouTube ale lui John Purcell. Sunt gratuite și foarte bine structurate.', 3),
                                                                                      (1, 3, 1, 'Și platforma Codecademy are un curs bun de Java pentru începători.', 2),
                                                                                      (4, 2, NULL, 'Foarte interesant proiectul! Ai făcut o treabă excelentă. Ai gândit să adaugi autentificare cu token JWT?', 4),
                                                                                      (4, 1, NULL, 'Codul arată foarte bine structurat. Felicitări!', 2);

-- Active users demo
INSERT INTO active_users (session_id, user_id, thread_id, ip_address) VALUES
                                                                          ('sess_001', 1, 1, '192.168.1.101'),
                                                                          ('sess_002', 2, 4, '192.168.1.102'),
                                                                          ('sess_003', 4, NULL, '192.168.1.103');

-- ===========================================
-- VERIFICARE
-- ===========================================

SELECT '✅ BAZA DE DATE CREATĂ CU SUCCES!' as Message;
SELECT '📊 STATISTICI:' as Info;
SELECT
    (SELECT COUNT(*) FROM users) as 'Utilizatori',
    (SELECT COUNT(*) FROM threads) as 'Thread-uri',
    (SELECT COUNT(*) FROM comments) as 'Comentarii',
    (SELECT COUNT(*) FROM tags) as 'Tag-uri',
    (SELECT COUNT(*) FROM active_users) as 'Utilizatori activi';

SELECT '👤 UTILIZATORI:' as Info;
SELECT user_id, username, email, role FROM users ORDER BY user_id;

SELECT '📝 THREAD-URI RECENTE:' as Info;
SELECT t.thread_id, u.username, t.title,
       DATE_FORMAT(t.created_at, '%d.%m.%Y %H:%i') as data_creare,
       t.view_count as vizualizari,
       t.vote_score as voturi
FROM threads t
         JOIN users u ON t.user_id = u.user_id
ORDER BY t.created_at DESC
    LIMIT 5;