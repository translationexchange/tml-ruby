# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokenizers::Xmessage do

  describe "parse" do
    it 'should correctly parse tokens' do
      language = Tml.config.default_language

      dt = Tml::Tokenizers::Xmessage.new('Hello World')
      expect(dt.tree).to eq([{:type => "trans", :value => "Hello World"}])
      expect(dt.substitute(language, [])).to eq("Hello World")

      dt = Tml::Tokenizers::Xmessage.new('{0} members')
      expect(dt.tree).to eq([{:type => "param", :index => "0"}, {:type => "trans", :value => " members"}])
      expect(dt.substitute(language, [2])).to eq("2 members")
      expect(dt.substitute(language, [0])).to eq("0 members")

      dt = Tml::Tokenizers::Xmessage.new('{0} {0,choice,singular#member|plural#members}')
      expect(dt.tree).to eq([{:type => "param", :index => "0"},
                             {:type => "trans", :value => " "},
                             {:index => "0",
                              :type => "choice",
                              :styles =>
                                  [{:key => "singular", :items => [{:type => "trans", :value => "member"}]},
                                   {:key => "plural", :items => [{:type => "trans", :value => "members"}]}]}])
      expect(dt.substitute(language, [1])).to eq("1 member")
      expect(dt.substitute(language, [0])).to eq("0 members")
      expect(dt.substitute(language, [2])).to eq("2 members")

      dt = Tml::Tokenizers::Xmessage.new('{0,choice,male#He|female#She|other#He/She} tagged {0,choice,himself#liked|female#herself} in {1} {1,choice,singular#photo|plural#photos}')


      #
      # {0} tagged himself/herself in a {1,map,photo#photo|video#video}
      #
      # Translator sees the original label as:
      #
      #              {0} tagged himself/herself in a photo/video.
      #
      # We ask the translators to provide translations for the following options based on context:
      #
      #             {0} tagged himself/herself in a photo.
      #             {
      #                context: {
      #
      #                },
      #
      #             }
      #
      # {0,choice,male#He|female#She|other#He/She} tagged {0,choice,himself#liked|female#herself} in {1} {1,choice,singular#photo|plural#photos}
      #
      # Original Label:
      #
      #              He/She tagged himself/herself in {1} photos
      #
      # Context rules:
      #
      #             [He] tagged himself in [{1}] photo
      #             {
      #               context: {
      #                   '0': {'gender': 'male'}, '1': {'number': 'singular'}
      #               },
      #               description: "{0} is a male and {1} is 1",
      #               default: 'He tagged himself in {1} photo'
      #             }
      #             [He] tagged himself in {1} photos
      #             [She] tagged herself in {1} photo
      #             [She] tagged herself in {1} photos
      #             [He/She] tagged himself/herself in {1} photo
      #             [He/She] tagged himself/herself in {1} photos
      #

      dt = Tml::Tokenizers::Xmessage.new('{0} {0,choice,singular#member|plural#members} and {1} {1,choice,singular#photo|plural#photos}')
      expect(dt.tree).to eq([
                                {:type => "param", :index => "0"},
                                {:type => "trans", :value => " "},
                                {:index => "0", :type => "choice", :styles => [{:key => "singular", :items => [{:type => "trans", :value => "member"}]}, {:key => "plural", :items => [{:type => "trans", :value => "members"}]}]},
                                {:type => "trans", :value => " and "},
                                {:type => "param", :index => "1"}, {:type => "trans", :value => " "}, {:index => "1", :type => "choice", :styles => [{:key => "singular", :items => [{:type => "trans", :value => "photo"}]}, {:key => "plural", :items => [{:type => "trans", :value => "photos"}]}]}
                            ])
      expect(dt.substitute(language, [1, 2])).to eq("1 member and 2 photos")
      expect(dt.substitute(language, [2, 1])).to eq("2 members and 1 photo")

      dt = Tml::Tokenizers::Xmessage.new('{:numViews,number,integer} {:numViews,choice,singular#view|plural#views}')
      expect(dt.tree).to eq([{:index => ":numViews", :type => "number", :value => "integer"},
                             {:type => "trans", :value => " "},
                             {:index => ":numViews",
                              :type => "choice",
                              :styles =>
                                  [{:key => "singular", :items => [{:type => "trans", :value => "view"}]},
                                   {:key => "plural", :items => [{:type => "trans", :value => "views"}]}]}])
      expect(dt.substitute(language, {numViews: 1})).to eq("1 view")
      expect(dt.substitute(language, {numViews: 5})).to eq("5 views")

      dt = Tml::Tokenizers::Xmessage.new('{0} tagged himself/herself in {1,choice,singular#{1,number} {2,map,photo#photo|video#video}|plural#{1,number} {2,map,photo#photos|video#videos}}.')
      expect(dt.substitute(language, ['Michael', 1, 'photo'])).to eq("Michael tagged himself/herself in 1 photo.")
      expect(dt.substitute(language, ['Michael', 5, 'photo'])).to eq("Michael tagged himself/herself in 5 photos.")
      expect(dt.substitute(language, ['Michael', 1, 'video'])).to eq("Michael tagged himself/herself in 1 video.")
      expect(dt.substitute(language, ['Michael', 5, 'video'])).to eq("Michael tagged himself/herself in 5 videos.")

      dt = Tml::Tokenizers::Xmessage.new('{0} tagged himself/herself in {1,number} {2,map,photo#{1,choice,singular#photo|plural#photos}|video#{1,choice,singular#video|plural#videos}}.')
      expect(dt.substitute(language, ['Michael', 1, 'photo'])).to eq("Michael tagged himself/herself in 1 photo.")
      expect(dt.substitute(language, ['Michael', 5, 'photo'])).to eq("Michael tagged himself/herself in 5 photos.")
      expect(dt.substitute(language, ['Michael', 1, 'video'])).to eq("Michael tagged himself/herself in 1 video.")
      expect(dt.substitute(language, ['Michael', 5, 'video'])).to eq("Michael tagged himself/herself in 5 videos.")

      dt = Tml::Tokenizers::Xmessage.new('You have {0,choice,singular#{2,anchor,text#{0,number} new {1,map,conn#connection|inv#invite}}|plural#{2,anchor,text#{0,number} new {1,map,conn#connections|inv#invites}}}.')
      expect(dt.tree).to eq([
                                {:type => "trans", :value => "You have "},
                                {:index => "0",
                                 :type => "choice",
                                 :styles =>
                                     [{:key => "singular",
                                       :items =>
                                           [{:index => "2",
                                             :type => "anchor",
                                             :styles =>
                                                 [{:key => "text",
                                                   :items =>
                                                       [{:type => "number", :index => "0"},
                                                        {:type => "trans", :value => " new "},
                                                        {:index => "1",
                                                         :type => "map",
                                                         :styles =>
                                                             [{:key => "conn",
                                                               :items => [{:type => "trans", :value => "connection"}]},
                                                              {:key => "inv",
                                                               :items => [{:type => "trans", :value => "invite"}]}]}]}]}]},
                                      {:key => "plural",
                                       :items =>
                                           [{:index => "2",
                                             :type => "anchor",
                                             :styles =>
                                                 [{:key => "text",
                                                   :items =>
                                                       [{:type => "number", :index => "0"},
                                                        {:type => "trans", :value => " new "},
                                                        {:index => "1",
                                                         :type => "map",
                                                         :styles =>
                                                             [{:key => "conn",
                                                               :items => [{:type => "trans", :value => "connections"}]},
                                                              {:key => "inv",
                                                               :items => [{:type => "trans", :value => "invites"}]}]}]}]}]}]},
                                {:type => "trans", :value => "."}
                            ])
      expect(dt.substitute(language, [1, 'conn', 'google.com'])).to eq("You have <a href='google.com'>1 new connection</a>.")
      expect(dt.substitute(language, [2, 'conn', 'google.com'])).to eq("You have <a href='google.com'>2 new connections</a>.")
      expect(dt.substitute(language, [3, 'inv', 'google.com'])).to eq("You have <a href='google.com'>3 new invites</a>.")
    end
  end

end

