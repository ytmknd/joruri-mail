class Sys::Admin::GroupsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)

    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = Sys::Group.find(id)

    @groups = Sys::Group.readable.where(parent_id: @parent.id).order(:sort_no, :code, :id)
    @users = Sys::User.readable.joins(:groups).where(sys_groups: { id: @parent.id })
      .order("LPAD(account, 15, '0')")
  end

  def index
    @items = Sys::Group.readable.where(parent_id: @parent.id).order(:id)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Sys::Group.find(params[:id])
    return error_auth unless @item.readable?
    _show @item
  end

  def new
    @item = Sys::Group.new(
      state: 'enabled',
      parent_id: @parent.id,
      ldap: 0,
      web_state: 'public'
    )
  end

  def create
    @item = Sys::Group.new(item_params)
    parent = Sys::Group.find_by(id: @item.parent_id)
    @item.level_no = parent ? parent.level_no + 1 : 1
    @item.call_update_child_level_no = true
    _create @item
  end

  def update
    @item = Sys::Group.find(params[:id])
    @item.attributes = item_params
    parent = Sys::Group.find_by(id: @item.parent_id)
    @item.level_no = parent ? parent.level_no + 1 : 1
    @item.call_update_child_level_no = true
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
    params.require(:item).permit(:state, :parent_id, :code, :name, :name_en, :ldap, :sort_no)
  end
end
