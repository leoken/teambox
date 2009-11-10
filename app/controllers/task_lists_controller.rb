class TaskListsController < ApplicationController
  before_filter :load_task_list, :only => [:update,:show,:destroy]
    
  def index
    if @current_project
      @task_lists = @current_project.task_lists.unarchived
      @activities = @current_project.activities.for_task_lists
    else
      @task_lists = []
      @activities = []
      current_user.projects.each do |project|
        @task_lists |= project.task_lists.unarchived
        @activities |= project.activities.for_task_lists
      end
    end
    
    respond_to do |f|
      f.html
      f.rss { render :layout => false }
    end
  end

  def new
    @task_list = @current_project.task_lists.new
  end
  
  def create
    @task_list = @current_project.new_task_list(current_user,params[:task_list])
    @task_list.save
    respond_to {|f|f.js}
  end
  
  def update
    @task_list.update_attributes(params[:task_list])
    respond_to {|f|f.js}
  end
  
  def show
    @task_lists = @current_project.task_lists.unarchived
    @comments = @task_list.comments
  ensure
    CommentRead.user(current_user).read_up_to(@comments.first) if @comments.first
  end
  
  def sortable
    @task_lists = @current_project.task_lists
    respond_to {|f|f.js}
  end
  
  def reorder
    params[:sortable_task_lists].each_with_index do |task_list_id,idx|
      task_list = @current_project.task_lists.find(task_list_id)
      task_list.update_attribute(:position,idx.to_i)
    end
  end  
 
  def archived
    @task_lists = @current_project.task_lists.with_archived_tasks
  end
  
  def destroy
    @task_list.destroy if @task_list.owner?(current_user)
    respond_to do |format|
      format.html { redirect_to project_task_lists_path(@current_project) }
      format.js
    end
  end
  
  def watch
    @task_list.add_watcher(current_user)
    respond_to{|f|f.js}
  end
  
  def unwatch
    @task_list.remove_watcher(current_user)
    respond_to{|f|f.js}
  end
  
  private
    def load_task_list
      @task_list = @current_project.task_lists.find(params[:id])
    end
end