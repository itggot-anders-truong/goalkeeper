module Database

    def connect()
        db = SQLite3::Database.new("db.db")
        return db
    end


    def create_user(username:,password:)
        db = connect()
        db.execute("INSERT INTO user(username,password) VALUES(?,?)", [username,password])
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
        db.execute("DELETE FROM groups WHERE id=?",id)
        db.execute("DELETE FROM members WHERE group_id=?",id)
        db.execute("DELETE FROM goal WHERE group_id=?",id)
    end

    def create_goal(id:,content:)
        db = connect()
        db.execute("INSERT INTO goal(content,group_id) VALUES(?,?)", [content, id])
        goal_id = db.execute("SELECT MAX(id) FROM goal")
        goalfollowers = db.execute("SELECT user_id FROM members WHERE group_id=? AND role=?", [id, "goalfollower"])
        goalfollowers.each do |user|
            db.execute("INSERT INTO to_do(user_id,goal_id,status) VALUES(?,?,?)", [user[0], goal_id, "not done"])
        end
    end

    def all_members(id:)
        db = connect()
        result = db.execute("SELECT * FROM user WHERE id IN (SELECT user_id FROM members WHERE group_id=?)", id)
        return result
    end
end