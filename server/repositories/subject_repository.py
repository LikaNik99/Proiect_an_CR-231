from sqlalchemy.orm import Session

from models.subject import Subject
from schemas.reference import SubjectCreate, SubjectUpdate


class SubjectRepository:
    def get_all(self, db: Session):
        return db.query(Subject).order_by(Subject.name).all()

    def get_by_id(self, db: Session, subject_id: int):
        return db.query(Subject).filter(Subject.id == subject_id).first()

    def get_by_code(self, db: Session, code: str):
        """Găsește un subiect după cod."""
        return db.query(Subject).filter(Subject.code == code).first()

    def create(self, db: Session, data: SubjectCreate):
        # Verifică dacă subiectul există deja după cod
        existing_subject = self.get_by_code(db, data.code)
        if existing_subject:
            # Dacă există, returnează subiectul existent
            return existing_subject
        
        # Dacă nu există, creează un subiect nou
        subject = Subject(
            name=data.name,
            code=data.code,
            semester=data.semester,
        )
        db.add(subject)
        db.commit()
        db.refresh(subject)
        return subject

    def update(self, db: Session, subject_id: int, data: SubjectUpdate):
        subject = self.get_by_id(db, subject_id)
        if not subject:
            return None

        # Dacă se schimbă codul, verifică dacă noul cod există deja
        if data.code is not None and data.code != subject.code:
            existing_subject = self.get_by_code(db, data.code)
            if existing_subject:
                # Dacă există deja un subiect cu noul cod, returnează eroare
                raise ValueError(f"Există deja un subiect cu codul '{data.code}'")

        if data.name is not None:
            subject.name = data.name
        if data.code is not None:
            subject.code = data.code
        if data.semester is not None:
            subject.semester = data.semester

        db.commit()
        db.refresh(subject)
        return subject

    def delete(self, db: Session, subject_id: int):
        subject = self.get_by_id(db, subject_id)
        if not subject:
            return None
        db.delete(subject)
        db.commit()
        return subject

