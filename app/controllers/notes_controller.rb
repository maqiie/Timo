class NotesController < ApplicationController
    before_action :authenticate_user! # Ensure authentication for all actions
  
    def index
      @notes = current_user.notes.all
    end
  
    def show
      @note = current_user.notes.find(params[:id])
    end
  
    def new
      @note = current_user.notes.build
    end
  
    def create
      @note = current_user.notes.build(note_params)
      if @note.save
        redirect_to @note, notice: 'Note was successfully created.'
      else
        render :new
      end
    end
  
    def edit
      @note = current_user.notes.find(params[:id])
    end
  
    def update
      @note = current_user.notes.find(params[:id])
      if @note.update(note_params)
        redirect_to @note, notice: 'Note was successfully updated.'
      else
        render :edit
      end
    end
  
    def destroy
      @note = current_user.notes.find(params[:id])
      @note.destroy
      redirect_to notes_url, notice: 'Note was successfully destroyed.'
    end
  
    private
  
    def note_params
      params.require(:note).permit(:title, :content)
    end
  end
  