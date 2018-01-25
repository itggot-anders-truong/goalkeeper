class App < Sinatra::Base
	require_relative 'module.rb'
	include Database
	enable :sessions

	get '/' do
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
		if session[:user_id] == nil
			redirect('/')
		end
		id = session[:user_id]
		groups = select_groups(id:id)
		slim(:main, locals:{groups:groups})
	end

	get '/group/memberlist/:id' do
		if session[:user_id] == nil
			redirect('/')
		end
		id = session[:user_id]
		group_id = params[:id]
		members = all_members(id:group_id)
		role = user_role(id:id,group_id:group_id)
		puts role.to_s
		puts members
		slim(:memberlist, locals:{members:members, role:role})
	end

	get '/group/:id' do
		if session[:user_id] == nil
			redirect('/')
		end
		id = session[:user_id]
		group_id = params[:id]
		role = user_role(id:id,group_id:group_id)
		goals = find_goals(group_id:group_id)
		slim(:group, locals:{role:role, goals:goals, group_id:group_id})
	end

	post '/register' do
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
		user_id = session[:user_id]
		code = params["code"]
		group_name = params["name"]
		create_group(id:user_id,name:group_name,code:code)
		redirect("/main")
	end

	post '/join_group' do
		code = params["code"]
		id = session[:user_id]
		join_group(id:id, code:code)
		redirect("/main")
	end

	post '/delete_group/:id' do
		id = params[:id]
		delete_group(id:id)
		redirect("/main")
	end

	post '/create_goal/:id' do
		id = params[:id]
		content = params["content"]
		create_goal(id:id,content:content)
		redirect("/group/#{id}")
	end
end           