module RailsAutolink
  module ::ActionView
    module Helpers
      module TextHelper
        private
          # remove "www\." pattern
          remove_const('AUTO_LINK_RE')
          AUTO_LINK_RE = %r{
              ((?:ed2k|ftp|http|https|irc|mailto|news|gopher|nntp|telnet|webcal|xmpp|callto|feed|svn|urn|aim|rsync|tag|ssh|sftp|rtsp|afs|file):)//
              [^\s<\u00A0"]+
            }ix
      end
    end
  end
end