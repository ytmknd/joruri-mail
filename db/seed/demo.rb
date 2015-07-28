# encoding: utf-8

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

g = Sys::Group.find_by_name_en('hisyokohoka')
Sys::UsersGroup.update_all({:group_id => g.id}, {:user_id => 1})
Sys::UsersGroup.create :user_id => 2, :group_id => g.id
Sys::UsersGroup.create :user_id => 3, :group_id => g.id
Sys::UsersGroup.create :user_id => 4, :group_id => g.id
g = Sys::Group.find_by_name_en('jinjika')
Sys::UsersGroup.create :user_id => 5 , :group_id => g.id
Sys::UsersGroup.create :user_id => 6 , :group_id => g.id
Sys::UsersGroup.create :user_id => 7 , :group_id => g.id
g = Sys::Group.find_by_name_en('kikakuseisakuka')
Sys::UsersGroup.create :user_id => 8 , :group_id => g.id
Sys::UsersGroup.create :user_id => 9 , :group_id => g.id
Sys::UsersGroup.create :user_id => 10, :group_id => g.id

## ---------------------------------------------------------
## current_user

Core.user       = Sys::User.find_by_account('admin')
Core.user_group = Core.user.groups[0]

## ---------------------------------------------------------
## cms/sites

### Cms::Site.update_all({:name => site_name})

## ---------------------------------------------------------
## cms/concepts
#
#def create_cms_concept(params)
#  params[:site_id]   ||= 1
#  params[:parent_id] ||= 1
#  params[:state]     ||= 'public'
#  if params[:parent_id] == 0
#    params[:level_no] = 1
#  else
#    parent = Cms::Concept.find_by_id(params[:parent_id])
#    params[:level_no] = parent.level_no + 1
#  end
#  Cms::Concept.create(params)
#end
#
#c_site  = Cms::Concept.find(1)
#c_site.name = site_name
#c_site.save
#
#c_top   = create_cms_concept :sort_no => 10 , :name => 'トップページ'
#c_mayor = create_cms_concept :sort_no => 30 , :name => '市長室'
#c_life  = create_cms_concept :sort_no => 50 , :name => 'ライフイベント'
#
## ---------------------------------------------------------
## cms/contents
#
#def create_cms_content(params)
#  params[:site_id]    ||= 1
#  params[:concept_id] ||= 1
#  params[:state]      ||= 'public'
#  Cms::Content.create(params)
#end
#
## ---------------------------------------------------------
## sys/roles
#
#r = Sys::RoleName.create :name => 'common', :title => '一般ユーザ'
#Sys::ObjectPrivilege.create :role_id => r.id, :item_unid => c_site.unid, :action => 'read'
#Sys::UsersRole.create :user_id => u2.id, :role_id => r.id
#Sys::UsersRole.create :user_id => u3.id, :role_id => r.id
#Sys::UsersRole.create :user_id => u4.id, :role_id => r.id
#
## ---------------------------------------------------------
## cms/layouts
#
#def create_cms_layout(params)
#  params[:site_id]     ||= 1
#  params[:concept_id]  ||= 1
#  params[:state]       ||= 'public'
#  params[:head]        ||= file("layouts/#{params[:name]}/head")
#  params[:body]        ||= file("layouts/#{params[:name]}/body")
#  params[:mobile_head] ||= file("layouts/#{params[:name]}/m_head")
#  params[:mobile_body] ||= file("layouts/#{params[:name]}/m_body")
#  Cms::Layout.create(params)
#end
#
#l_top      = create_cms_layout :concept_id => c_top.id  , :name => 'top'             , :title => 'トップページ'
#l_map      = create_cms_layout :concept_id => c_site.id , :name => 'sitemap'         , :title => 'サイトマップ'
#l_mayor    = create_cms_layout :concept_id => c_mayor.id, :name => 'mayor'           , :title => '市長の部屋'
#l_life     = create_cms_layout :concept_id => c_life.id , :name => 'lifeevent'       , :title => 'ライフイベント'
#l_life_top = create_cms_layout :concept_id => c_life.id , :name => 'lifeevent-top'   , :title => 'ライフイベントTOP'
#l_page     = create_cms_layout :concept_id => c_site.id , :name => 'page'            , :title => '詳細ページ'
#l_top_emg1 = create_cms_layout :concept_id => c_top.id  , :name => 'emergency-level1', :title => '大規模災害トップページ１'
#l_top_emg2 = create_cms_layout :concept_id => c_top.id  , :name => 'emergency-level2', :title => '大規模災害トップページ２'
#l_top_emg3 = create_cms_layout :concept_id => c_top.id  , :name => 'emergency-level3', :title => '大規模災害トップページ３'
#
## ---------------------------------------------------------
## cms/pieces
#
#def create_cms_piece(params)
#  params[:site_id]        ||= 1
#  params[:concept_id]     ||= 1
#  params[:state]          ||= 'public'
#  params[:body]           ||= file("pieces/#{params[:name]}/body")
#  params[:xml_properties] ||= file("pieces/#{params[:name]}/xml_properties")
#  Cms::Piece.create(params)
#end
#
#[ [ c_site.id , 'Cms::Free'      , 'ad-lower'             , '広告（下部）' ],
#  [ c_site.id , 'Cms::Free'      , 'ad-upper'             , '広告（右上部）' ],
#  [ c_site.id , 'Cms::Free'      , 'address'              , '住所' ],
#  [ c_site.id , 'Cms::PageTitle' , 'page-title'           , 'ページタイトル' ],
#  [ c_site.id , 'Cms::BreadCrumb', 'bread-crumbs'         , 'パンくず' ],
#  [ c_site.id , 'Cms::Free'      , 'global-navi'          , 'グローバルナビ' ],
#  [ c_site.id , 'Cms::Free'      , 'footer-navi'          , 'フッターナビ' ],
#  [ c_site.id , 'Cms::Free'      , 'common-banner'        , 'サイトバナー' ],
#  [ c_site.id , 'Cms::Free'      , 'common-header'        , 'ふりがな・よみあげヘッダー' ],
#  [ c_site.id , 'Cms::Free'      , 'recent-docs-title'    , '新着情報タイトル' ],
#  [ c_site.id , 'Cms::Free'      , 'attract-information'  , '注目情報' ],
#  [ c_site.id , 'Cms::Free'      , 'relation-link'        , '関連リンク' ],
#  [ c_top.id  , 'Cms::Free'      , 'about'                , 'ジョールリ市の紹介' ],
#  [ c_top.id  , 'Cms::Free'      , 'application'          , '申請書ダウンロード' ],
#  [ c_top.id  , 'Cms::Free'      , 'area-information'     , '地域情報' ],
#  [ c_top.id  , 'Cms::Free'      , 'basic-information'    , '基本情報' ],
#  [ c_top.id  , 'Cms::Free'      , 'common-banner-top'    , 'サイトバナー（トップ）' ],
#  [ c_top.id  , 'Cms::Free'      , 'mayor'                , '市長室' ],
#  [ c_top.id  , 'Cms::Free'      , 'qr-code'              , 'QRコード' ],
#  [ c_top.id  , 'Cms::Free'      , 'photo'                , 'トップ写真' ],
#  [ c_top.id  , 'Cms::Free'      , 'useful-information'   , 'お役立ち情報' ],
#  [ c_top.id  , 'Cms::Free'      , 'topic'                , 'トピック' ],
#  [ c_top.id  , 'Cms::Free'      , 'lifeevent'            , 'ライフイベント' ],
#  [ c_top.id  , 'Cms::Free'      , 'category'             , 'カテゴリ' ],
#  [ c_top.id  , 'Cms::Free'      , 'inquiry'              , 'お問い合わせバナー' ],
#  [ c_top.id  , 'Cms::Free'      , 'population'           , '人口' ],
#  [ c_mayor.id, 'Cms::Free'      , 'mayor-side'           , '市長室サイドメニュー' ],
#  [ c_mayor.id, 'Cms::Free'      , 'mayor'                , '市長室' ],
#  [ c_mayor.id, 'Cms::Free'      , 'mayor-title'          , '市長室タイトル' ],
#  [ c_life.id , 'Cms::Free'      , 'lifeevent-title'      , 'ライフイベントタイトル' ],
#  [ c_life.id , 'Cms::Free'      , 'lifeevent-side'       , 'ライフイベントサイドメニュー' ],
#  [ c_site.id , 'Cms::Free'      , 'mobile-common-header' , 'モバイル：ヘッダー画像' ],
#  [ c_site.id , 'Cms::Free'      , 'mobile-copyright'     , 'モバイル：コピーライト' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-address'       , 'モバイル：住所' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-category-list' , 'モバイル：トップ分野一覧' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-footer-navi'   , 'モバイル：フッターナビ' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-mayor'         , 'モバイル：ようこそ市長室へ' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-menu-navi'     , 'モバイル：ナビ' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-pickup'        , 'モバイル：ピックアップ' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-recommend-site', 'モバイル：おすすめサイト' ],
#  [ c_top.id  , 'Cms::Free'      , 'mobile-search'        , 'モバイル：サイト内検索' ],
#  [ c_site.id , 'Cms::Free'      , 'mobile-back-navi'     , 'モバイル：バックナビ' ],
#  [ c_site.id , 'Cms::Free'      , 'mobile-mayor-navi'    , 'モバイル：市長室' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency'                 , '大規模災害表示ピース　緊急アナウンス ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-application'     , '大規模災害表示ピース　申請書ダウンロード ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-area-information', '大規模災害表示ピース　地域情報 ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-common-banner'   , '大規模災害表示ピース　サイトバナー ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-info'            , '大規模災害表示ピース　緊急情報 ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-inquiry'         , '大規模災害表示ピース　お問い合わせバナー ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-link-bousai'     , '大規模災害表示ピース　リンク集(防災関係機関) ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-link-kasen'      , '大規模災害表示ピース　リンク集(河川情報) ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-link-koutsuu'    , '大規模災害表示ピース　リンク集(交通情報) ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-link-lifeline'   , '大規模災害表示ピース　リンク集(ライフライン情報) ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-mailmagazine'    , '大規模災害表示ピース　メールマガジン ' ],
#  [ c_top.id  , 'Cms::Free'      , 'emergency-mode'            , '大規模災害表示ピース　モード表示' ],
#].each do |c|
#  create_cms_piece :concept_id => c[0], :model => c[1], :name => c[2], :title => c[3]
#end
#
## ---------------------------------------------------------
## cms/nodes
#
#def create_cms_node(params)
#  params[:site_id]        ||= 1
#  params[:concept_id]     ||= 1
#  params[:parent_id]      ||= 1
#  params[:state]          ||= 'public'
#  params[:route_id]       ||= params[:parent_id]
#  params[:directory]      ||= (params[:name] =~ /\./ ? 0 : 1)
#  params[:published_at]   ||= Time.now
#  Cms::Node.create(params)
#end
#
#Cms::Node.update_all({:layout_id => l_top.id}, {:id => 1})
#Cms::Node.update_all({:concept_id => c_top.id, :layout_id => l_top.id}, {:id => 2})
#create_cms_node :parent_id => 1, :layout_id => l_page.id, :model => 'Cms::Page'     , :name => 'mobile.html', :title => 'ジョールリ市携帯サイトのご紹介', :body => file("nodes/pages/mobile/body")
#
#p = create_cms_node :layout_id => l_map.id, :model => 'Cms::Directory', :name => 'sitemap'   , :title => 'サイトマップ'
#    create_cms_node :layout_id => l_map.id, :model => 'Cms::Sitemap'  , :name => 'index.html', :title => 'サイトマップ',
#      :parent_id => p.id 
#
#m = create_cms_node :concept_id => c_mayor.id, :layout_id => l_mayor.id, :model => 'Cms::Directory', :name => 'mayor'     , :title => '市長室'
#    create_cms_node :concept_id => c_mayor.id, :layout_id => l_mayor.id, :model => 'Cms::Page'     , :name => 'index.html', :title => '市長のご挨拶', :body => file("nodes/mayor/index/body"),
#      :parent_id => m.id 
#p = create_cms_node :parent_id => m.id, :concept_id => c_mayor.id, :layout_id => l_mayor.id, :model => 'Cms::Directory', :name => 'profile'   , :title => 'プロフィール'
#    create_cms_node :parent_id => p.id, :concept_id => c_mayor.id, :layout_id => l_mayor.id, :model => 'Cms::Page'     , :name => 'index.html', :title => 'プロフィール', :body => file("nodes/mayor/dummy/body")
#p = create_cms_node :parent_id => m.id, :concept_id => c_mayor.id, :layout_id => l_mayor.id, :model => 'Cms::Directory', :name => 'activity'  , :title => '市長へのメール'
#    create_cms_node :parent_id => p.id, :concept_id => c_mayor.id, :layout_id => l_mayor.id, :model => 'Cms::Page'     , :name => 'index.html', :title => '市長へのメール', :body => file("nodes/mayor/dummy/body")
#
#p = create_cms_node :parent_id => 1   , :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Directory', :name => 'lifeevent'    , :title => 'ライフイベント'
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life_top.id, :model => 'Cms::Page'     , :name => 'index.html'   , :title => 'ライフイベント', :body => file("nodes/life/index/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'fukushi.html' , :title => '福祉・介護'    , :body => file("nodes/life/fukushi/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'hikkoshi.html', :title => '引越し'        , :body => file("nodes/life/hikkoshi/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'kekkon.html'  , :title => '結婚・離婚'    , :body => file("nodes/life/kekkon/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'kosodate.html', :title => '子育て・教育'  , :body => file("nodes/life/kosodate/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'ninshin.html' , :title => '妊娠・出産'    , :body => file("nodes/life/ninshin/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'seijin.html'  , :title => '成人になったら', :body => file("nodes/life/seijin/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'shibo.html'   , :title => '死亡'          , :body => file("nodes/life/shibo/body")
#    create_cms_node :parent_id => p.id, :concept_id => c_life.id, :layout_id => l_life.id    , :model => 'Cms::Page'     , :name => 'shushoku.html', :title => '就職・退職'    , :body => file("nodes/life/shushoku/body")
#
## ---------------------------------------------------------
## cms/site_settings
#
#def create_cms_site_setting(params)
#  params[:site_id]        ||= 1
#  Cms::SiteSetting.create(params)
#end
#
#create_cms_site_setting(:name => "emergency_layout", :value => l_top.id     , :sort_no => 0)
#create_cms_site_setting(:name => "emergency_layout", :value => l_top_emg1.id, :sort_no => 10)
#create_cms_site_setting(:name => "emergency_layout", :value => l_top_emg2.id, :sort_no => 20)
#create_cms_site_setting(:name => "emergency_layout", :value => l_top_emg3.id, :sort_no => 30)
#
## ---------------------------------------------------------
## other modules
#
#load_seed_file "demo/article.rb"
#load_seed_file "demo/enquete.rb"
#load_seed_file "demo/portal.rb"
#load_seed_file "demo/newsletter.rb"
load_seed_file "demo/sys.rb"
load_seed_file "demo/gw.rb"

puts "Imported demo data."
