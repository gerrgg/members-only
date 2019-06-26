module SessionsHelper

    
    def log_in(user)
        session[:user_id] = user.id
    end

    def current_user
        # equals user_id = session[:user_id]; if user_id
        if (user_id = session[:user_id])
            @current_user ||= User.find_by(id: user_id)
        elsif (user_id = cookies.signed[:user_id])
            user = User.find_by(id: user_id)
            if user && user.authenticated?('remember', cookies[:remember_token])
                log_in user
                @current_user = user
            end
        end
    end

    def current_user?(user)
        user == current_user
    end


    def logged_in?
        !session[:user_id].nil?
    end

    def log_out
        session[:user_id] = nil
        @current_user = nil
    end

    def remember(user)
        user.remember
        cookies.signed.permanent[:user_id] = user.id
        cookies.permanent[:remember_token] = user.remember_token
    end

    def forget(user)
        user.forget
        cookies[:remember_token] = nil
    end

end
