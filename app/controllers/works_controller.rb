class WorksController < ApplicationController
  # We should always be able to tell what category
  # of work we're dealing with
  before_action :category_from_url, only: [:index, :new, :create]
  before_action :category_from_work, except: [:root, :index, :new, :create]
  skip_before_action :require_login, only: [:root]

  def root
    @albums = Work.best_albums
    @books = Work.best_books
    @movies = Work.best_movies
    @best_work = Work.order(vote_count: :desc).first
  end

  def index
    @media = Work.by_category(@media_category).order(vote_count: :desc)
    render :index
  end

  def new
    @work = Work.new(category: @media_category)
  end

  def create
    @work = Work.new(media_params)
    # raise
    if @work.save
      flash[:status] = :success
      flash[:result_text] = "Successfully created #{@media_category.singularize} #{@work.id}"
      redirect_to works_path(@media_category)
    else
      flash[:status] = :failure
      flash[:result_text] = "Could not create #{@media_category.singularize}"
      flash[:messages] = @work.errors.messages
      render :new, status: :bad_request
    end
  end

  def show
    @votes = @work.votes.order(created_at: :desc)
  end

  def edit
    @work = find_user.works.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to work_path(params[:id]), message: "You cannot edit this event."
  end

  def update
    # @work.update_attributes(media_params) unless @work.user != find_user

    @work.update_attributes(media_params)
    if @work.save
      flash[:status] = :success
      flash[:result_text] = "Successfully updated #{@media_category.singularize} #{@work.id}"
      redirect_to works_path(@media_category)
    else
      flash.now[:status] = :failure
      flash.now[:result_text] = "Could not update #{@media_category.singularize}"
      flash.now[:messages] = @work.errors.messages
      render :edit, status: :not_found
    end
  end

  def destroy
    # if @work.user == find_user
    @work = find_user.works.find(params[:id])

    @work.destroy
    flash[:status] = :success
    flash[:result_text] = "Successfully destroyed #{@media_category.singularize} #{@work.id}"
    redirect_to root_path

  rescue ActiveRecord::RecordNotFound
    redirect_to work_path(params[:id]), message: "You cannot delete this event."
    # else
    #   flash.now[:status] = :error
    #   flash[:result_text] = "You are not the owner of this work so you cannot change it"
    #   render 'show'
    # end
  end

  def upvote
    # Most of these varied paths end in failure
    # Something tragically beautiful about the whole thing
    # For status codes, see
    # http://stackoverflow.com/questions/3825990/http-response-code-for-post-when-resource-already-exists
    flash[:status] = :failure
    if @login_user
      vote = Vote.new(user: @login_user, work: @work)
      if vote.save
        flash[:status] = :success
        flash[:result_text] = "Successfully upvoted!"
        status = :found
      else
        flash[:result_text] = "Could not upvote"
        flash[:messages] = vote.errors.messages
        status = :conflict
      end
    else
      flash[:result_text] = "You must log in to do that"
      status = :unauthorized
    end

    # Refresh the page to show either the updated vote count
    # or the error message
    redirect_back fallback_location: works_path(@media_category), status: status
  end

  private
  def media_params
    params.require(:work).permit(:title, :category, :user_id, :creator, :description, :publication_year)
  end

  def category_from_url
    @media_category = params[:category].downcase.pluralize
  end

  def category_from_work
    @work = Work.find_by(id: params[:id])
    render_404 unless @work
    @media_category = @work.category.downcase.pluralize
  end
end
