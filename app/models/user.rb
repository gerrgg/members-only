class User < ApplicationRecord
    has_many :posts, dependent: :destroy
    attr_accessor :remember_token, :activation_token, :reset_password_token

    before_save :downcase_email
    before_create :create_activation_digest


    validates :name, presence: true
    
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    validates :email, presence: true, length: { maximum: 255 },
    format: { with: VALID_EMAIL_REGEX },
    uniqueness: { case_sensitive: false }
    
    
    has_secure_password
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

    def User.new_token
        SecureRandom.urlsafe_base64
    end

    def User.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end

    def remember
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(self.remember_token))
    end

    def forget
        self.remember_token = nil
        update_attribute(:remember_digest, nil)
    end

    def authenticated?(attribute, token)
        digest = send("#{attribute}_digest")
        return false if digest.nil?
        BCrypt::Password.new(digest).is_password?(token)
    end

    def send_activation_email
        UserMailer.account_activation(self).deliver_now
    end

    def activate
        update_columns(activated: true, activated_at: Time.zone.now)
    end

    def create_reset_password_digest
        self.reset_password_token = User.new_token
        update_attribute(:reset_password_digest, User.digest(reset_password_token))
        update_attribute(:reset_sent_at, Time.zone.now)
    end

    def send_reset_password_email
        UserMailer.reset_password(self).deliver_now
    end

    def password_reset_expired?
        reset_sent_at < 2.hours.ago
    end
        
    
    private

    def downcase_email
        email.downcase!
    end

    # Creates and assigns the activation token and digest
    def create_activation_digest
        self.activation_token = User.new_token
        self.activation_digest = User.digest(activation_token)
    end
end
