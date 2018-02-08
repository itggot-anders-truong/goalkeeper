class App < Sinatra::Base
	require_relative 'module.rb'
	include Database
	enable :sessions

	def auto_redirect()
		if session[:user_id] == nil
			redirect('/')
		end
	end

	get '/' do
		session[:user_id] = nil
		slim(:index)
	end

	get '/register' do
		slim(:register)
	end

	get '/error' do
		error = session[:error]
		slim(:error, locals:{error:error})
	end

	get '/main' do
		auto_redirect()
		id = session[:user_id]
		groups = select_groups(id:id)
		current_user = find_username(id:session[:user_id])
		slim(:main, locals:{current_user:current_user, groups:groups,current_user:current_user})
	end

	get '/group/memberlist/:id' do
		auto_redirect()
		id = session[:user_id]
		group_id = params[:id]
		role_list = []
		members = all_members(id:group_id)
		members.each do |member|
			user_role = user_role(id: member[0], group_id:group_id)
			role_list.push(user_role[0][0])
		end
		role = user_role(id:id,group_id:group_id)
		current_user = find_username(id:session[:user_id])
		slim(:memberlist, locals:{current_user:current_user, members:members, role:role, group_id:group_id, role_list:role_list})
	end

	get '/group/:id' do
		auto_redirect()
		id = session[:user_id]
		group_id = params[:id]
		role = user_role(id:id,group_id:group_id)
		goals = find_goals(group_id:group_id)
		current_user = find_username(id:session[:user_id])
		slim(:group, locals:{current_user:current_user, role:role, goals:goals, group_id:group_id, id:id})
	end

	get '/:group_id/goal/:id' do
		auto_redirect()
		group_id = params[:group_id]
		id = params[:id]
		status_list = []
		user_role = user_role(id:session[:user_id], group_id:group_id)[0][0]
		members = all_members(id:group_id)
		goal = goal_info(id:id)
		members.each do |member|
			begin
				user_status = check_status(id:member[0],goal_id:id)
				status_list.push(user_status[0][2])
			rescue NoMethodError
				create_goal_for_user(id:session[:user_id],goal_id:id)
				retry
			end
		end
		current_user = find_username(id:session[:user_id])
		slim(:goal, locals:{current_user:current_user, goal:goal, goal_id:id, members:members, status_list:status_list, user_role:user_role})
	end

	get '/group/create_goal/:group_id' do
		auto_redirect()
		group_id = params[:group_id]
		current_user = find_username(id:session[:user_id])
		slim(:create_goal, locals:{current_user:current_user, group_id:group_id})
	end

	post '/register' do
		auto_redirect()
		username = params["username"]
		password = params["password"]
		confirm = params["confirm"]
		if password.length > 0 && username.length > 0
			if password == confirm
				password_digest = BCrypt::Password.create(password)
				begin
					create_user(username:username,password:password_digest)
				rescue SQLite3::ConstraintException
					session[:error] = "Username already exist"
					redirect("/error")
				end
			else
				session[:error] = "Passwords does not match"
				redirect("/error")
			end
			redirect("/")
		else
			session[:error] = "You must fill all the forms"
			redirect("/error")
		end
	end

	post '/login' do
		username = params["username"]
		password = params["password"]
		info = login_info(username:username)
		begin
			password_digest = info[0][2]
		rescue NoMethodError
			session[:error] = "Invalid Credentials"
			redirect("/error")
		end
		if BCrypt::Password.new(password_digest) == password
			session[:user_id] = info[0][0]
			redirect("/main")
		else
			session[:error] = "Invalid Credentials"
			redirect("/error")
		end
	end

	post '/create_group' do
		auto_redirect()
		user_id = session[:user_id]
		code = params["code"]
		group_name = params["name"]
		create_group(id:user_id,name:group_name,code:code)
		redirect("/main")
	end

	post '/join_group' do
		auto_redirect()
		code = params["code"]
		id = session[:user_id]
		join_group(id:id, code:code)
		redirect("/main")
	end

	post '/delete_group/:id' do
		auto_redirect()
		id = params[:id]
		delete_group(id:id)
		redirect("/main")
	end

	post '/group/create_goal/create_goal/:id' do
		auto_redirect()
		id = params[:id]
		title = params["title"]
		description = params["description"]
		create_goal(id:id,title:title,description:description)
		redirect("/group/#{id}")
	end

	post '/group/memberlist/changerole/:group_id/:user_id' do
		auto_redirect()
		id = params[:user_id]
		group_id = params[:group_id]
		role = check_role(id:id)
		p role[0][0]
		if role[0][0].chomp == "goalkeeper"
			role_count = check_role_count(group_id:group_id)
			p role_count
			if role_count.length > 1
				change_to_goalfollower(id:id)
			else
				session[:error] = "Not enough goalkeepers"
				redirect("/error")
			end
		elsif role[0][0].chomp == "goalfollower"
			change_to_goalkeeper(id:id)
		end
		redirect("/group/memberlist/#{group_id}")
	end

	post '/:group_id/goal/change_status/:goal_id/:member_id' do
		auto_redirect()
		group_id = params[:group_id]
		goal_id = params[:goal_id]
		member_id = params[:member_id]
		change_status(member_id:member_id, goal_id:goal_id)
		redirect("/#{group_id}/goal/#{goal_id}")
	end

	post '/logout' do
		session[:user_id] = nil
		auto_redirect()
	end


	post '/group/leave_group/:id/:group_id' do
		auto_redirect()
		id = params[:id]
		group_id = params[:group_id]
		leave_group(id:id, group_id:group_id)
		redirect("/main")
	end
end           	