### site_name = "ジョールリ市"

load "#{Rails.root}/db/seed/base.rb"

## ---------------------------------------------------------
## methods

def file(path)
  file = "#{Rails.root}/db/seed/demo/#{path}.txt"
  FileTest.exist?(file) ? File.new(file).read.force_encoding('utf-8') : nil
end

## ---------------------------------------------------------
## sys/groups

def create(parent, level_no, sort_no, code, name, name_en)
  Sys::Group.create :parent_id => (parent == 0 ? 0 : parent.id), :level_no => level_no, :sort_no => sort_no,
    :state => 'enabled', :web_state => 'closed',
    :ldap => 0, :code => code, :name => name, :name_en => name_en
end

r = Sys::Group.find(1)
p = create r, 2, 2 , '001'   , '企画部'        , 'kikakubu'
    create p, 3, 1 , '001001', '部長室'        , 'buchoshitsu'
    create p, 3, 2 , '001002', '秘書広報課'    , 'hisyokohoka'
    create p, 3, 3 , '001003', '人事課'        , 'jinjika'
    create p, 3, 4 , '001004', '企画政策課'    , 'kikakuseisakuka'
    create p, 3, 5 , '001005', '行政情報室'    , 'gyoseijohoshitsu'
    create p, 3, 6 , '001006', 'IT推進課'      , 'itsuishinka'
p = create r, 2, 3 , '002'   , '総務部'        , 'somubu'
    create p, 3, 1 , '002001', '部長室'        , 'buchoshitsu'
    create p, 3, 2 , '002002', '財政課'        , 'zaiseika'
    create p, 3, 3 , '002003', '庁舎建設推進室', 'chosyakensetsusuishinka'
    create p, 3, 4 , '002004', '管財課'        , 'kanzaika'
    create p, 3, 5 , '002005', '税務課'        , 'zeimuka'
    create p, 3, 6 , '002006', '納税課'        , 'nozeika'
    create p, 3, 7 , '002007', '市民安全局'    , 'shiminanzenkyoku'
p = create r, 2, 4 , '003'   , '市民部'        , 'shiminbu'
p = create r, 2, 5 , '004'   , '環境管理部'    , 'kankyokanribu'
p = create r, 2, 6 , '005'   , '保健福祉部'    , 'hokenhukushibu'
p = create r, 2, 7 , '006'   , '産業部'        , 'sangyobu'
p = create r, 2, 8 , '007'   , '建設部'        , 'kensetsubu'
p = create r, 2, 9 , '008'   , '特定事業部'    , 'tokuteijigyobu'
p = create r, 2, 10, '009'   , '会計'          , 'kaikei'
p = create r, 2, 11, '010'   , '水道部'        , 'suidobu'
p = create r, 2, 12, '011'   , '教育委員会'    , 'kyoikuiinkai'
p = create r, 2, 13, '012'   , '議会'          , 'gikai'
p = create r, 2, 14, '013'   , '農業委員会'    , 'nogyoiinkai'
p = create r, 2, 15, '014'   , '選挙管理委員会', 'senkyokanriiinkai'
p = create r, 2, 16, '015'   , '監査委員'      , 'kansaiin'
p = create r, 2, 17, '016'   , '公平委員会'    , 'koheiiinkai'
p = create r, 2, 18, '017'   , '消防本部'      , 'syobohonbu'
p = create r, 2, 19, '018'   , '住民センター'  , 'jumincenter'
p = create r, 2, 20, '019'   , '公民館'        , 'kominkan'

## ---------------------------------------------------------
## sys/users

def create(auth_no, name, account, password, email)
  Sys::User.create :state => 'enabled', :ldap => 0, :auth_no => auth_no,
    :name => name, :account => account, :password => password,
    :mobile_access => 1, :mobile_password => password,
    :email => email
end

u2 = create 2, '徳島　太郎'  , 'user1', 'user1', 'user1@demo.joruri.org' # 秘書広報課
u3 = create 2, '徳島　花子'  , 'user2', 'user2', 'user2@demo.joruri.org' # 秘書広報課
u4 = create 2, '吉野　三郎'  , 'user3', 'user3', 'user3@demo.joruri.org' # 秘書広報課
u4 = create 2, '佐藤　直一'  , 'user4', 'user4', 'user4@demo.joruri.org' # 人事課
u4 = create 2, '鈴木　裕介'  , 'user5', 'user5', 'user5@demo.joruri.org' # 人事課
u4 = create 2, '高橋　和寿'  , 'user6', 'user6', 'user6@demo.joruri.org' # 人事課
u4 = create 2, '田中　彩子'  , 'user7', 'user7', 'user7@demo.joruri.org' # 企画政策課
u4 = create 2, '渡辺　真由子', 'user8', 'user8', 'user8@demo.joruri.org' # 企画政策課
u4 = create 2, '伊藤　勝'    , 'user9', 'user9', 'user9@demo.joruri.org' # 企画政策課

## ---------------------------------------------------------
## sys/users_groups

g = Sys::Group.find_by(name_en: 'hisyokohoka')
Sys::UsersGroup.where(user_id: 1).update_all(group_id: g.id)
Sys::UsersGroup.create :user_id => 2, :group_id => g.id
Sys::UsersGroup.create :user_id => 3, :group_id => g.id
Sys::UsersGroup.create :user_id => 4, :group_id => g.id
g = Sys::Group.find_by(name_en: 'jinjika')
Sys::UsersGroup.create :user_id => 5 , :group_id => g.id
Sys::UsersGroup.create :user_id => 6 , :group_id => g.id
Sys::UsersGroup.create :user_id => 7 , :group_id => g.id
g = Sys::Group.find_by(name_en: 'kikakuseisakuka')
Sys::UsersGroup.create :user_id => 8 , :group_id => g.id
Sys::UsersGroup.create :user_id => 9 , :group_id => g.id
Sys::UsersGroup.create :user_id => 10, :group_id => g.id

## ---------------------------------------------------------
## current_user

Core.user       = Sys::User.find_by(account: 'admin')
Core.user_group = Core.user.groups[0]

load_seed_file "demo/sys.rb"
load_seed_file "demo/webmail.rb"

puts "Imported demo data."
