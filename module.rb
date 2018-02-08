module Database

    def connect()
        db = SQLite3::Database.new("db.db")
        return db
    end

    def create_user(username:,password:)
        db = connect()
        db.execute("INSERT INTO user(username,password) VALUES(?,?)", [username,password])
    end

    def find_username(id:)
        db = connect()
        result = db.execute("SELECT username FROM user WHERE id = ?", id)
        return result[0][0]
    end

    def login_info(username:)
        db = connect()
        result = db.execute("SELECT * FROM user WHERE username = ?", username)
        return result
    end

    def create_group(id:,name:,code:)
        db = connect()
        db.execute("INSERT INTO groups(name,code) VALUES(?,?)", [name,code])
        group_id = db.execute("SELECT MAX(id) FROM groups")
        db.execute("INSERT INTO members(user_id,group_id,role) VALUES(?,?,?)", [id, group_id, "goalkeeper"])
    end

    def select_groups(id:)
        db = connect()
        result = db.execute("SELECT * FROM groups WHERE id IN (SELECT group_id FROM members WHERE user_id=?)", id)
        return result
    end

    def join_group(id:,code:)
        db = connect()
        group_id = db.execute("SELECT id FROM groups WHERE code=?", code)
        db.execute("INSERT INTO members(user_id,group_id,role) VALUES(?,?,?)", [id, group_id, "goalfollower"])
    end

    def user_role(id:,group_id:)
        db = connect()
        result = db.execute("SELECT role FROM members WHERE user_id=? AND group_id=?", [id, group_id])
        return result
    end

    def find_goals(group_id:)
        db = connect()
        result = db.execute("SELECT * FROM goal WHERE group_id=?", group_id)
        return result
    end

    def delete_group(id:)
        db = connect()
        db.execute("DELETE FROM to_do WHERE goal_id IN (SELECT id FROM goal WHERE group_id=?)", id)
        db.execute("DELETE FROM groups WHERE id=?",id)
        db.execute("DELETE FROM members WHERE group_id=?",id)
        db.execute("DELETE FROM goal WHERE group_id=?",id)
    end

    def create_goal(id:,title:, description:)
        db = connect()
        db.execute("INSERT INTO goal(title,group_id,description) VALUES(?,?,?)", [title, id, description])
        goal_id = db.execute("SELECT MAX(id) FROM goal")
        members = db.execute("SELECT * FROM members WHERE group_id=?", id)
        members.each do |user|
            if user[2] == "goalfollower"
                db.execute("INSERT INTO to_do(user_id,goal_id,status) VALUES(?,?,?)", [user[0], goal_id, "not done"])
            elsif user[2] == "goalkeeper"
                db.execute("INSERT INTO to_do(user_id,goal_id,status) VALUES(?,?,?)", [user[0], goal_id, "done"])
            end
        end
    end

    def goal_info(id:)
        db = connect()
        db.execute("SELECT * FROM goal WHERE id=?", id)
    end

    def all_members(id:)
        db = connect()
        result = db.execute("SELECT * FROM user WHERE id IN (SELECT user_id FROM members WHERE group_id=?)", id)
        return result
    end

    def change_to_goalkeeper(id:)
        db = connect()
        db.execute("UPDATE members SET role=? WHERE user_id=?", ["goalkeeper", id])
    end

    def change_to_goalfollower(id:)
        db = connect()
        db.execute("UPDATE members SET role=? WHERE user_id=?", ["goalfollower", id])
    end

    def check_role_count(group_id:)
        db = connect()
        db.execute("SELECT * FROM members WHERE group_id=? AND role=?", [group_id, "goalkeeper"])
    end

    def check_status(id:,goal_id:)
        db = connect()
        db.execute("SELECT * FROM to_do WHERE user_id=? AND goal_id=?", [id,goal_id])
    end

    def change_status(member_id:, goal_id:)
        db = connect()
        status = check_status(id:member_id, goal_id:goal_id)[0][2]
        if status == "not done"
            db.execute("UPDATE to_do SET status=? WHERE user_id=?", ["done", member_id])
        elsif status == "done"
            db.execute("UPDATE to_do SET status=? WHERE user_id=?", ["not done", member_id])
        end
    end

    def leave_group(id:, group_id:)
        db = connect()
        db.execute("DELETE FROM members WHERE user_id=? AND group_id=?", [id,group_id])
        db.execute("DELETE FROM to_do WHERE user_id=? AND goal_id IN (SELECT id FROM goal WHERE group_id=?)", [id,group_id])
    end

    def create_goal_for_user(id:,goal_id:)
        db = connect()
        db.execute("INSERT INTO to_do(user_id,goal_id,status) VALUES(?,?,?)", [id, goal_id, "not done"])
    end
end