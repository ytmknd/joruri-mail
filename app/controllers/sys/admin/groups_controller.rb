class Sys::Admin::GroupsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)

    @parent = Sys::Group.find_by(id: params[:parent]) || Sys::Group.new(id: 0, level_no: 0)
  end

  def index
    @groups = Sys::Group.where(parent_id: @parent.id).order(:sort_no, :tenant_code, :code, :id)
    @users = Sys::User.joins(:groups).where(sys_groups: { id: @parent.id })
      .order("LPAD(account, 15, '0')")
    _index @groups
  end

  def show
    @item = Sys::Group.find(params[:id])
    return error_auth unless @item.readable?
    _show @item
  end

  def new
    @item = Sys::Group.new(
      parent_id: @parent.id,
      state: 'enabled',
      ldap: 0,
      web_state: 'public'
    )
  end

  def create
    @item = Sys::Group.new(item_params)

    @item.tenant_code = @item.parent.tenant_code if @item.parent
    @item.level_no = @item.parent.try!(:level_no).to_i + 1
    @item.update_include_descendants = true

    _create @item
  end

  def update
    @item = Sys::Group.find(params[:id])
    @item.attributes = item_params

    @item.tenant_code = @item.parent.tenant_code if @item.parent
    @item.level_no = @item.parent.try!(:level_no).to_i + 1
    @item.update_include_descendants = true

    _update @item
  end

  def destroy
    @item = Sys::Group.find(params[:id])
    _destroy @item
  end

  def assign_sort_no
    groups = Sys::Group.all.to_a
    
    groups.sort! do |a, b|
      if a.parent_id == 0 && b.parent_id == 0
        a.id <=> b.id
      elsif a.parent_id == 0
        -1
      elsif b.parent_id == 0
        1
      else
        fill_zero_before(a.code, 255) <=> fill_zero_before(b.code, 255)
      end
    end

    err = 0
    groups.each_with_index do |g, i|
      g.sort_no = (i+1) * 10
      err += 1 unless g.save(validate: false)
    end

    if err == 0
      flash[:notice] = "並び順を採番しました。"
    else
      flash[:notice] = "#{groups.length}件中#{err}件の並び順の採番に失敗しました。"
    end

    redirect_to action: :index
  end

  private

  def fill_zero_before(s, max)
    len = s.length
    ss = len < max ? "0"*(max-len) + s : s
  end

  def item_params
    params.require(:item).permit(
      :tenant_code, :state, :parent_id, :code, :name, :name_en, :ldap, :sort_no
    )
  end
end
