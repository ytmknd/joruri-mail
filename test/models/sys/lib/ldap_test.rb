require 'test_helper'

class Sys::Lib::LdapTest < ActiveSupport::TestCase
  FakeEntry = Struct.new(:dn, :attributes) do
    def each(&block)
      attributes.each(&block)
    end
  end

  class FakeConnection
    attr_reader :calls

    def initialize(entries)
      @entries = entries
      @calls = []
    end

    def search(base:, scope:, filter:)
      @calls << { base: base, scope: scope, filter: filter }
      @entries.each { |entry| yield entry }
    end
  end

  def test_search_converts_net_ldap_entries_to_legacy_entry_objects
    ldap = Sys::Lib::Ldap.new(host: 'ldap.example.test', port: 389, base: 'dc=example,dc=test')
    fake_connection = FakeConnection.new([
      FakeEntry.new(
        'uid=user1,dc=example,dc=test',
        uid: ['user1'],
        cn: ['User One'],
        'givenname;lang-en' => ['One']
      )
    ])
    ldap.instance_variable_set(:@connection, fake_connection)

    entries = ldap.search('(uid=user1)', class: Sys::Lib::Ldap::User)

    assert_equal 1, entries.size
    assert_equal 'uid=user1,dc=example,dc=test', entries.first.dn
    assert_equal 'user1', entries.first.uid
    assert_equal 'User One', entries.first.name
    assert_equal 'One', entries.first.get('givenName;lang-en')
    assert_equal 'dc=example,dc=test', fake_connection.calls.first[:base]
    assert_equal Sys::Lib::Ldap::SCOPE_SUBTREE, fake_connection.calls.first[:scope]
    assert_instance_of Net::LDAP::Filter, fake_connection.calls.first[:filter]
  end
end
