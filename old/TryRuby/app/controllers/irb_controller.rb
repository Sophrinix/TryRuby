class IrbController < ApplicationController
  # GET /irb
  # GET /irb.xml
  def index
    
    @irb = []

    respond_to do |format|
      format.html # index.html.erb
      format.to_json
      format.xml  { render :xml => @irb }
    end
  end

  # GET /irb/1
  # GET /irb/1.xml
  def show
    @irb = Irb.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @irb }
    end
  end

  # GET /irb/new
  # GET /irb/new.xml
  def new
    @irb = Irb.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @irb }
    end
  end

  # GET /irb/1/edit
  def edit
    @irb = Irb.find(params[:id])
  end

  # POST /irb
  # POST /irb.xml
  def create
    @irb = Irb.new(params[:irb])

    respond_to do |format|
      if @irb.save
        format.html { redirect_to(@irb, :notice => 'Irb was successfully created.') }
        format.xml  { render :xml => @irb, :status => :created, :location => @irb }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @irb.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /irb/1
  # PUT /irb/1.xml
  def update
    @irb = Irb.find(params[:id])

    respond_to do |format|
      if @irb.update_attributes(params[:irb])
        format.html { redirect_to(@irb, :notice => 'Irb was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @irb.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /irb/1
  # DELETE /irb/1.xml
  def destroy
    @irb = Irb.find(params[:id])
    @irb.destroy

    respond_to do |format|
      format.html { redirect_to(irb_url) }
      format.xml  { head :ok }
    end
  end
end
