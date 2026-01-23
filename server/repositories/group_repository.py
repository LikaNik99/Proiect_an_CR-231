from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from models.group import Group
from models.schedule import Schedule
from models.user_group import UserGroup
from schemas.reference import GroupCreate, GroupUpdate


class GroupRepository:
    def get_all(self, db: Session):
        return db.query(Group).order_by(Group.code).all()

    def get_by_id(self, db: Session, group_id: int):
        return db.query(Group).filter(Group.id == group_id).first()

    def create(self, db: Session, data: GroupCreate):
        group = Group(
            code=data.code,
            year=data.year,
            faculty=data.faculty,
            specialization=data.specialization,
        )
        db.add(group)
        db.commit()
        db.refresh(group)
        return group

    def update(self, db: Session, group_id: int, data: GroupUpdate):
        group = self.get_by_id(db, group_id)
        if not group:
            return None

        try:
            if data.code is not None:
                group.code = data.code
            if data.year is not None:
                group.year = data.year
            if data.faculty is not None:
                group.faculty = data.faculty
            if data.specialization is not None:
                group.specialization = data.specialization

            db.commit()
            db.refresh(group)
            return group
        except IntegrityError as e:
            db.rollback()
            raise ValueError(f"Eroare la actualizarea grupei: {str(e)}")
        except Exception as e:
            db.rollback()
            raise ValueError(f"Eroare neașteptată la actualizarea grupei: {str(e)}")

    def delete(self, db: Session, group_id: int):
        """
        Șterge o grupă. Dacă grupa are relații (schedules sau user_groups),
        șterge automat aceste relații înainte de a șterge grupa.
        """
        group = self.get_by_id(db, group_id)
        if not group:
            return None
        
        try:
            # Verifică dacă există schedule-uri asociate
            schedules_count = db.query(Schedule).filter(Schedule.group_id == group_id).count()
            if schedules_count > 0:
                # Șterge toate schedule-urile asociate
                db.query(Schedule).filter(Schedule.group_id == group_id).delete()
            
            # Verifică dacă există user_groups asociate
            user_groups_count = db.query(UserGroup).filter(UserGroup.group_id == group_id).count()
            if user_groups_count > 0:
                # Șterge toate asociările user_groups
                db.query(UserGroup).filter(UserGroup.group_id == group_id).delete()
            
            # Șterge grupa
            db.delete(group)
            db.commit()
            return group
        except IntegrityError as e:
            db.rollback()
            raise ValueError(f"Nu se poate șterge grupa: există relații care o referențiază. {str(e)}")
        except Exception as e:
            db.rollback()
            raise ValueError(f"Eroare la ștergerea grupei: {str(e)}")

