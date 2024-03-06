# class PostsController < ApplicationController
#     # before_action :authenticate_user!, except: [:index, :show]
  
#     def index
#       @posts = Post.all
#     end
  
#     def show
#       @post = Post.find(params[:id])
#     end
  
#     def new
#       @post = Post.new
#     end
#     def create
#         @post = Post.new(post_params)
      
#         if @post.save
#           redirect_to @post, notice: 'Post was successfully created.'
#         else
#           render :new
#         end
#       end
      
#     # def create
#     #   @post = current_user.posts.build(post_params)
  
#     #   if @post.save
#     #     redirect_to @post, notice: 'Post was successfully created.'
#     #   else
#     #     render :new
#     #   end
#     # end
  
#     def edit
#       @post = current_user.posts.find(params[:id])
#     end
  
#     def update
#       @post = current_user.posts.find(params[:id])
  
#       if @post.update(post_params)
#         redirect_to @post, notice: 'Post was successfully updated.'
#       else
#         render :edit
#       end
#     end
  
#     def destroy
#       @post = current_user.posts.find(params[:id])
#       @post.destroy
#       redirect_to posts_url, notice: 'Post was successfully destroyed.'
#     end
  
#     private
#     def post_params
#         params.permit(:content, :image)
#       end
  
#     def post_params
#       params.require(:post).permit(:title, :content, :image)
#     end
#   end
class PostsController < ApplicationController
    # before_action :authenticate_user!, except: [:index, :show]
  
    def index
      @posts = Post.all
    end
  
    def show
      @post = Post.find(params[:id])
    end
  
    def new
      @post = Post.new
    end
  
    def create
        @post = Post.new(post_params)
        @post.image.attach(params[:image]) if params[:image]
    
        if @post.save
          redirect_to @post, notice: 'Post was successfully created.'
        else
          render :new
        end
      end
  
    def edit
      @post = current_user.posts.find(params[:id])
    end
  
    def update
      @post = current_user.posts.find(params[:id])
  
      if @post.update(post_params)
        redirect_to @post, notice: 'Post was successfully updated.'
      else
        render :edit
      end
    end
  
    def destroy
      @post = current_user.posts.find(params[:id])
      @post.destroy
      redirect_to posts_url, notice: 'Post was successfully destroyed.'
    end
  
    private
    def post_params
      params.permit(:content, :image, :title)
    end
  end
  