# encoding: UTF-8

require 'spec_helper'

describe Tml::Language do
  describe "#initialize" do
    it "sets language attributes" do
      @russian = Tml::Language.new(load_json('languages/ru.json'))
      expect(@russian.locale).to eq('ru')
      expect(@russian.full_name).to eq("Russian - Русский")
      expect(@russian.dir).to eq("ltr")

      expect(@russian.align("left")).to eq("left")

      expect(@russian.current_source(:source => "custom")).to eq("custom")
      expect(@russian.current_source({})).to eq("undefined")

      expect(@russian.has_definition?).to be_truthy

      expect(@russian.context_by_keyword(:number)).to be_truthy
      expect(@russian.context_by_keyword(:numeric)).to be_falsey
      expect(@russian.context_by_token_name('count').keyword).to eq('number')
      expect(@russian.context_by_token_name('num').keyword).to eq('number')
      expect(@russian.context_by_token_name('user').keyword).to eq('gender')
      expect(@russian.context_by_token_name('actor').keyword).to eq('gender')
      expect(@russian.context_by_token_name('target').keyword).to eq('gender')
      expect(@russian.context_by_token_name('profile').keyword).to eq('gender')
      expect(@russian.context_by_token_name('users').keyword).to eq('genders')
      expect(@russian.context_by_token_name('date').keyword).to eq('date')
      expect(@russian.context_by_token_name('bla').keyword).to eq('value')
    end
  end

  describe 'normalize locale' do
    it 'should return correct locale' do
      expect(Tml::Language.normalize_locale('en')).to eq('en')
      expect(Tml::Language.normalize_locale('EN')).to eq('en')
      expect(Tml::Language.normalize_locale('eN')).to eq('en')
      expect(Tml::Language.normalize_locale('en_us')).to eq('en-US')
      expect(Tml::Language.normalize_locale('en-us')).to eq('en-US')
      expect(Tml::Language.normalize_locale('en-Us')).to eq('en-US')
      expect(Tml::Language.normalize_locale('en-US')).to eq('en-US')
      expect(Tml::Language.normalize_locale('EN-US')).to eq('en-US')
      expect(Tml::Language.normalize_locale('az-Cyrl-AZ')).to eq('az-Cyrl-AZ')
      expect(Tml::Language.normalize_locale('az-cyrl-az')).to eq('az-Cyrl-AZ')
      expect(Tml::Language.normalize_locale('az_cyrl_az')).to eq('az-Cyrl-AZ')
      expect(Tml::Language.normalize_locale('AZ_cyrl_AZ')).to eq('az-Cyrl-AZ')
      expect(Tml::Language.normalize_locale('AZ_CYRL_AZ')).to eq('az-Cyrl-AZ')
    end
  end

  describe "testing translations" do
    before do
      Tml.session.current_translator = nil

      @app = init_application
      @english = @app.language('en')
      @russian = @app.language('ru')
    end

    describe "basic translations" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do
          load_translation_key_from_hash(@app, {
              "label" => "Hello World",
              "translations" => {
              "ru" => [
                  {
                    "label"=> "Привет Мир"
                  }
                ]
              }
          })

          expect(@english.translate('Hello World')).to eq("Hello World")
          expect(@russian.translate('Hello World')).to eq("Привет Мир")

          load_translation_key_from_array(@app, [{
            "label" => "Invite",
            "description" => "An invitation",
            "translations" => {
                "ru" => [
                    {
                        "label"=> "Приглашение"
                    }
                ]
            }
          }, {
            "label" => "Invite",
            "description" => "An action to invite",
            "translations" => {
                "ru" => [
                    {
                        "label"=> "Приглашать"
                    }
                ]
            }
          }])

          expect(@english.translate('Invite', 'An invitation')).to eq("Invite")
          expect(@english.translate('Invite', 'An action to invite')).to eq("Invite")
          expect(@russian.translate('Invite', 'An invitation')).to eq("Приглашение")
          expect(@russian.translate('Invite', 'An action to invite')).to eq("Приглашать")
        end
      end
    end

    describe "numeric tokens" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          expect(@english.translate('You have {count||message}.', :count => 0)).to eq("You have 0 messages.")
          expect(@english.translate('You have {count||message}.', :count => 1)).to eq("You have 1 message.")
          expect(@english.translate('You have {count||message}.', :count => 5)).to eq("You have 5 messages.")

          load_translation_key_from_hash(@app, {
              "label" => "You have {count||message}.",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "У вас есть {count|| one: сообщение, few: сообщения, other: сообщений}."
                      }
                  ]
              }
          })

          expect(@russian.translate('You have {count||message}.', :count => 0)).to eq("У вас есть 0 сообщений.")
          expect(@russian.translate('You have {count||message}.', :count => 1)).to eq("У вас есть 1 сообщение.")
          expect(@russian.translate('You have {count||message}.', :count => 2)).to eq("У вас есть 2 сообщения.")
          expect(@russian.translate('You have {count||message}.', :count => 23)).to eq("У вас есть 23 сообщения.")
          expect(@russian.translate('You have {count||message}.', :count => 5)).to eq("У вас есть 5 сообщений.")
          expect(@russian.translate('You have {count||message}.', :count => 15)).to eq("У вас есть 15 сообщений.")


          # Shorter form

          load_translation_key_from_hash(@app, {
              "label" => "You have {count||message}.",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "У вас есть {count|| сообщение, сообщения, сообщений}."
                      }
                  ]
              }
          })

          expect(@russian.translate('You have {count||message}.', :count => 0)).to eq("У вас есть 0 сообщений.")
          expect(@russian.translate('You have {count||message}.', :count => 1)).to eq("У вас есть 1 сообщение.")
          expect(@russian.translate('You have {count||message}.', :count => 2)).to eq("У вас есть 2 сообщения.")
          expect(@russian.translate('You have {count||message}.', :count => 23)).to eq("У вас есть 23 сообщения.")
          expect(@russian.translate('You have {count||message}.', :count => 5)).to eq("У вас есть 5 сообщений.")
          expect(@russian.translate('You have {count||message}.', :count => 15)).to eq("У вас есть 15 сообщений.")

          # Alternative form

          load_translation_key_from_hash(@app, {
              "label" => "You have {count||message}.",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "У вас есть {count} сообщение.",
                          "context"=> {
                            "count"=> { "number" => "one"}
                          }
                      },
                      {
                          "label"=> "У вас есть {count} сообщения.",
                          "context"=> {
                              "count"=> { "number" => "few"}
                          }
                      },
                      {
                          "label"=> "У вас есть {count} сообщений.",
                          "context"=> {
                              "count"=> { "number" => "many"}
                          }
                      }
                  ]
              }
          })

          expect(@russian.translate('You have {count||message}.', :count => 0)).to eq("У вас есть 0 сообщений.")
          expect(@russian.translate('You have {count||message}.', :count => 1)).to eq("У вас есть 1 сообщение.")
          expect(@russian.translate('You have {count||message}.', :count => 2)).to eq("У вас есть 2 сообщения.")
          expect(@russian.translate('You have {count||message}.', :count => 23)).to eq("У вас есть 23 сообщения.")
          expect(@russian.translate('You have {count||message}.', :count => 5)).to eq("У вас есть 5 сообщений.")
          expect(@russian.translate('You have {count||message}.', :count => 15)).to eq("У вас есть 15 сообщений.")

        end
      end
    end

    describe "gender tokens" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          female = {:gender => :female, :name => "Anna"}
          male = {:gender => :male, :name => "Michael"}

          expect(@english.translate('{user} updated {user| male: his, female: her} profile.', :user => {:object => female, :attribute => :name})).to eq("Anna updated her profile.")
          expect(@english.translate('{user} updated {user| his, her} profile.', :user => {:object => female, :attribute => :name})).to eq("Anna updated her profile.")

          expect(@english.translate('{user} updated {user| male: his, female: her} profile.', :user => {:object => male, :attribute => :name})).to eq("Michael updated his profile.")
          expect(@english.translate('{user} updated {user| his, her} profile.', :user => {:object => male, :attribute => :name})).to eq("Michael updated his profile.")

          load_translation_key_from_hash(@app, {
              "label" => "{user} updated {user| his, her} profile.",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "{user|| male: обновил, female: обновила} свой профиль."
                      }
                  ]
              }
          })

          expect(@russian.translate('{user} updated {user| his, her} profile.', :user => {:object => female, :attribute => :name})).to eq("Anna обновила свой профиль.")
          expect(@russian.translate('{user} updated {user| his, her} profile.', :user => {:object => male, :attribute => :name})).to eq("Michael обновил свой профиль.")

          load_translation_key_from_hash(@app, {
              "label" => "{user} updated {user| his, her} profile.",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "{user|| обновил, обновила} свой профиль."
                      }
                  ]
              }
          })

          expect(@russian.translate('{user} updated {user| his, her} profile.', :user => {:object => female, :attribute => :name})).to eq("Anna обновила свой профиль.")
          expect(@russian.translate('{user} updated {user| his, her} profile.', :user => {:object => male, :attribute => :name})).to eq("Michael обновил свой профиль.")

          Tml.config.format = :html
          Tml.session.current_translator = Tml::Translator.new
          Tml.session.current_translator.inline = true
          expect(@russian.translate('{user} updated {user| his, her} profile.', :user => {:object => male, :attribute => :name})).to eq("<tml:label class='tml_translatable tml_translated' data-translation_key='d42ca2ae9e2d198bc3aec92925922826' data-target_locale='ru'><tml:token class='tml_token tml_token_transform' data-name='user'>Michael</tml:token> обновил свой профиль.</tml:label>")
          Tml.session.current_translator.inline = false
          Tml.config.format = :plain
        end
      end
    end

    describe "gender tokens with language cases" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          female = {:gender => :female, :name => "Anna"}
          male = {:gender => :male, :name => "Michael"}

          expect(@english.translate('You like {user::pos} post.', :user => {:object => male, :attribute => :name})).to eq("You like Michael's post.")

          Tml.config.format = :html
          Tml.session.current_translator = Tml::Translator.new
          Tml.session.current_translator.inline = true
          expect(@english.translate('You like {user::pos} post.', :user => {:object => male, :attribute => :name})).to eq("You like <tml:token class='tml_token tml_token_data' data-name='user' data-case='pos'><tml:case class=\"tml_language_case\" data-locale=\"en\" data-rule=\"eyJrZXl3b3JkIjoicG9zIiwibGFuZ3VhZ2VfbmFtZSI6IkVuZ2xpc2ggKFVTKSIsImxhdGluX25hbWUiOiJQb3NzZXNzaXZlIiwibmF0aXZlX25hbWUiOm51bGwsImNvbmRpdGlvbnMiOiIodHJ1ZSkiLCJvcGVyYXRpb25zIjoiKGFwcGVuZCBcIidzXCIgQHZhbHVlKSIsIm9yaWdpbmFsIjoiTWljaGFlbCIsInRyYW5zZm9ybWVkIjoiTWljaGFlbCdzIn0%3D\">Michael's</tml:case></tml:token> post.")
          Tml.session.current_translator.inline = false
          Tml.config.format = :plain

          expect(@english.translate('{actor} liked {target::pos} post.', :actor => {:object => female, :attribute => :name}, :target => {:object => male, :attribute => :name})).to eq("Anna liked Michael's post.")

          female = {:gender => :female, :name => "Анна"}
          male = {:gender => :male, :name => "Михаил"}


          load_translation_key_from_hash(@app, {
              "label" => "{actor} liked {target::pos} post.",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "{actor::dat} понравилось сообщение {target::gen}."
                      }
                  ]
              }
          })

          expect(@russian.translate('{actor} liked {target::pos} post.', :actor => {:object => female, :attribute => :name}, :target => {:object => male, :attribute => :name})).to eq("Анне понравилось сообщение Михаила.")
          expect(@russian.translate('{actor} liked {target::pos} post.', :actor => {:object => male, :attribute => :name}, :target => {:object => female, :attribute => :name})).to eq("Михаилу понравилось сообщение Анны.")

        end
      end
    end

    describe "decoration tokens" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          expect(@english.translate("[bold: This text] should be bold", :bold => lambda{|text| "<strong>#{text}</strong>"})).to eq("<strong>This text</strong> should be bold")

          load_translation_key_from_hash(@app, {
              "label" => "[bold: This text] should be bold",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "[bold: Этот текст] должны быть жирным"
                      }
                  ]
              }
          })

          expect(@russian.translate("[bold: This text] should be bold", :bold => lambda{|text| "<strong>#{text}</strong>"})).to eq("<strong>Этот текст</strong> должны быть жирным")

        end
      end
    end

    describe "nested decoration tokens" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          expect(@english.translate("[bold: Bold text [italic: with italic text]] together", :bold => "<b>{$0}</b>", :italic => "<i>{$0}</i>")).to eq("<b>Bold text <i>with italic text</i></b> together")

          load_translation_key_from_hash(@app, {
              "label" => "[bold: Bold text [italic: with italic text]] together",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "[bold: Жирный текст [italic: с курсив]] вместе"
                      }
                  ]
              }
          })

          expect(@russian.translate("[bold: Bold text [italic: with italic text]] together", :bold => "<b>{$0}</b>", :italic => "<i>{$0}</i>")).to eq("<b>Жирный текст <i>с курсив</i></b> вместе")

        end
      end
    end


    describe "nested decoration tokens with data tokens" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          user = {:gender => :male, :name => "Michael"}

          expect(@english.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 1, :link => "<a href='url'>{$0}</a>")).to eq("<b>Michael</b> received <a href='url'><b>1</b> message</a>")
          expect(@english.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 5, :link => "<a href='url'>{$0}</a>")).to eq("<b>Michael</b> received <a href='url'><b>5</b> messages</a>")

          load_translation_key_from_hash(@app, {
              "label" => "[bold: {user}] received [link: [bold: {count}] {count|message}]",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "[bold: {user}] {user| получил, получила} [link: [bold: {count}] {count| сообщение, сообщения, сообщений}]"
                      }
                  ]
              }
          })

          expect(@russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 1, :link => "<a href='url'>{$0}</a>")).to eq("<b>Michael</b> получил <a href='url'><b>1</b> сообщение</a>")
          expect(@russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 2, :link => "<a href='url'>{$0}</a>")).to eq("<b>Michael</b> получил <a href='url'><b>2</b> сообщения</a>")
          expect(@russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 5, :link => "<a href='url'>{$0}</a>")).to eq("<b>Michael</b> получил <a href='url'><b>5</b> сообщений</a>")

          user = {:gender => :female, :name => "Anna"}

          expect(@russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 1, :link => "<a href='url'>{$0}</a>")).to eq("<b>Anna</b> получила <a href='url'><b>1</b> сообщение</a>")
          expect(@russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 2, :link => "<a href='url'>{$0}</a>")).to eq("<b>Anna</b> получила <a href='url'><b>2</b> сообщения</a>")
          expect(@russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 5, :link => "<a href='url'>{$0}</a>")).to eq("<b>Anna</b> получила <a href='url'><b>5</b> сообщений</a>")

        end
      end
    end


    describe "date translations" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          Tml.session.current_language = @english

          date = Date.new(2011, 01, 01)
          expect(@english.translate("This message was received on {date}", :date => date)).to eq("This message was received on 2011-01-01")

          expect(date.translate()).to eq("1/1/2011")
          expect(date.tr()).to eq("1/1/2011")
          expect(@english.translate("This message was received on {date}", :date => date.tr())).to eq("This message was received on 1/1/2011")

          expect(date.tr(:verbose)).to eq("Saturday, January 1, 2011")
          expect(@english.translate("This message was received on {date}", :date => date.tr(:verbose))).to eq("This message was received on Saturday, January 1, 2011")

          Tml.config.localization[:custom_date_formats][:short_numeric] = '%m/%d'
          expect(@english.translate("This message was received on {date}", :date => date.tr(:short_numeric))).to eq("This message was received on 1/1")
          expect(@english.translate("This message was received on {date}", :date => date.tr("%B %d"))).to eq("This message was received on January 1")
          expect(@english.translate("This message was received on {date}", :date => date.tr("{month_name} {days::ord}"))).to eq("This message was received on January 1st")

          expect(@english.translate("This message was received on {date}", :date => date.tr("{month_name} {days}"))).to eq("This message was received on January 1")

          load_translation_key_from_array(@app, [{
              "label" => "{month_name} {days}",
              "translations" => {
                "ru" => [
                    {
                        "label"=> "{days}ого {month_name::gen}"
                    }
                ]
              }
          }, {
              "label" => "This message was received on {date}",
              "translations" => {
                "ru" => [
                    {
                        "label"=> "Это сообщение было получено {date}"
                    }
                ]
              }
          }, {
              "label" => "January",
              "description" => "Month name",
              "translations" => {
                "ru" => [
                    {
                        "label"=> "Январь"
                    }
                ]
              }
          }])

          expect(@russian.translate("January", "Month name")).to eq("Январь")
          expect(@russian.translate('' + Tml.config.default_month_name(0), "Month name")).to eq("Январь")

          Tml.session.current_language = @russian
          expect(@russian.translate("This message was received on {date}", :date => date.tr("{month_name} {days}"))).to eq("Это сообщение было получено 1ого Января")
        end
      end
    end


    describe "time translations" do
      it "should return correct translations" do
        Tml.session.with_block_options(:dry => true) do

          time = Time.new(2014, 01, 02, 11, 12, 13)

          expect(time.translate()).to eq("1/2/2014")
          expect(time.tr()).to eq("1/2/2014")

          Tml.session.current_language = @english

          expect(@english.translate("This message was received on {time}", :time => time.tr(:date_time))).to eq("This message was received on 1/2/2014 at 11:12")

          expect(@english.translate("This message was received on {time}", :time => time.tr("{month_name} {days::ord} at {short_hours}:{minutes} {am_pm}"))).to eq("This message was received on January 2nd at 11:12 AM")

          load_translation_key_from_array(@app, [{
               "label" => "{month_name} {days::ord} at {short_hours}:{minutes} {am_pm}",
               "translations" => {
                   "ru" => [
                       {
                           "label"=> "{days}ого {month_name::gen} в {short_hours}:{minutes} {am_pm}"
                       }
                   ]
               }
           }, {
               "label" => "This message was received on {time}",
               "translations" => {
                   "ru" => [
                       {
                           "label"=> "Это сообщение было получено {time}"
                       }
                   ]
               }
           }, {
               "label" => "January",
               "description" => "Month name",
               "translations" => {
                   "ru" => [
                       {
                           "label"=> "Январь"
                       }
                   ]
               }
          }, {
             "label" => "AM",
             "description" => "Meridian indicator",
             "translations" => {
                 "ru" => [
                     {
                         "label"=> "бп"
                     }
                 ]
             }
          } , {
              "label" => "PM",
              "description" => "Meridian indicator",
              "translations" => {
                  "ru" => [
                      {
                          "label"=> "пп"
                      }
                  ]
              }
          }])

          Tml.session.current_language = @russian
          expect(@russian.translate("This message was received on {time}", :time => time.tr("{month_name} {days::ord} at {short_hours}:{minutes} {am_pm}"))).to eq("Это сообщение было получено 2ого Января в 11:12 бп")
        end
      end
    end

  end


  describe "#translation" do
    #before do
    #  @@app = init_application
    #  @@english = @app.language('en')
    #  @@russian = @app.language('ru')
    #end
    #
    #it "translates with fallback to English" do
    #  Tml.session.with_block_options(:dry => true) do
    #    #expect(@@russian.translate("{count||message}", {:count => 1})).to eq("1 message")
    #    #expect(@@russian.translate("{count||message}", {:count => 5})).to eq("5 messages")
    #    #expect(@@russian.translate("{count||message}", {:count => 0})).to eq("0 messages")
    #  end
    #end

    #  it "translates basic phrases to Russian" do
    #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@@russian.translate("Hello World")).to eq("Привет Мир")
    #      expect(@@russian.translate("Hello World", "Wrong context")).to eq("Hello World")
    #      expect(@@russian.translate("Hello World", "Greeting context")).to eq("Привет Мир")
    #      expect(@@russian.translate("Hello world")).to eq("Hello world")
    #      expect(@@russian.translate("Hello {user}", nil, :user => "Михаил")).to eq("Привет Михаил")
    #    end
    #  end
    #
    #  it "translates basic phrases with data tokens to Russian" do
    #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@@russian.translate("Hello {user}", nil, :user => "Михаил")).to eq("Привет Михаил")
    #    end
    #  end
    #
    #  it "uses default data tokens" do
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@english.translate("He said: {quot}Hello{quot}", nil)).to eq("He said: &quot;Hello&quot;")
    #      expect(@english.translate("Code sample: {lbrace}a:'b'{rbrace}", nil)).to eq("Code sample: {a:'b'}")
    #    end
    #  end
    #
    #  it "uses basic decoration tokens" do
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@english.translate("Hello [decor: World]", nil, :decor => lambda{|text| "''#{text}''"})).to eq("Hello ''World''")
    #    end
    #  end
    #
    #  it "uses default decoration tokens" do
    #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@english.translate("Hello [i: World]")).to eq("Hello <i>World</i>")
    #      expect(@@russian.translate("Hello [i: World]")).to eq("Привет <i>Мир</i>")
    #    end
    #  end
    #
    #  it "uses mixed tokens" do
    #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@english.translate("Hello [i: {user}]", nil, :user => "Michael")).to eq("Hello <i>Michael</i>")
    #      expect(@@russian.translate("Hello [i: {user}]", nil, :user => "Michael")).to eq("Привет <i>Michael</i>")
    #    end
    #  end
    #
    #  it "uses method tokens" do
    #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@@russian.translate("Hello {user.first_name} [i: {user.last_name}]", nil,
    #        :user => stub_object({:first_name => "Tom", :last_name => "Anderson"}))).to eq("Привет Tom <i>Anderson</i>")
    #    end
    #  end
    #
    #  it "translates phrases with numeric rules to Russian" do
    #    load_translation_keys_from_file(@app, 'translations/ru/counters.json')
    #    trn = @@russian.translate("{count||message}", nil, {:count => 1})
    #    expect(trn).to eq("1 сообщение")
    #    trn = @@russian.translate("{count||message}", nil, {:count => 2})
    #    expect(trn).to eq("2 сообщения")
    #    trn = @@russian.translate("{count||message}", nil, {:count => 5})
    #    expect(trn).to eq("5 сообщений")
    #    trn = @@russian.translate("{count||message}", nil, {:count => 15})
    #    expect(trn).to eq("15 сообщений")
    #  end
    #
    #  it "translates phrases with gender rules to Russian" do
    #    #load_translation_key_from_hash(@app, {
    #    #    "label" => "{actor} sent {target} a gift.",
    #    #    "translations" => {
    #    #    "ru" => [
    #    #        {
    #    #          "label"=> "{actor} послал подарок {target::dat}.",
    #    #          "locale"=> "ru",
    #    #          "context"=> {
    #    #            "actor"=> [{ "type"=> "gender", "key"=> "male"}]
    #    #          }
    #    #        },
    #    #        {
    #    #          "label"=> "{actor} послала подарок {target::dat}.",
    #    #          "locale"=> "ru",
    #    #          "context"=> {
    #    #            "actor"=> [{ "type"=> "gender", "key"=> "female"}]
    #    #          },
    #    #        },
    #    #        {
    #    #          "label"=> "{actor} послал/а подарок {target::dat}.",
    #    #          "locale"=> "ru",
    #    #          "context"=> {
    #    #            "actor"=> [{ "type"=> "gender", "key"=> "unknown"}]
    #    #           },
    #    #        }
    #    #      ]
    #    #    }
    #    #});
    #
    #    load_translation_keys_from_file(@app, "translations/ru/genders.json")
    #
    #    actor = {'gender' => 'female', 'name' => 'Таня'}
    #    target = {'gender' => 'male', 'name' => 'Михаил'}
    #
    #    Tml.config.with_block_options(:dry => true) do
    #      expect(@@russian.translate(
    #                      '{actor} sent {target} a gift.', nil,
    #                      :actor => {:object => actor, :attribute => 'name'},
    #                      :target => {:object => target, :attribute => 'name'})
    #      ).to eq("Таня послала подарок Михаилу.")
    #
    #      expect(@@russian.translate(
    #                      '{actor} sent {target} a gift.', nil,
    #                      :actor => {:object => target, :attribute => 'name'},
    #                      :target => {:object => actor, :attribute => 'name'})
    #      ).to eq("Михаил послал подарок Тане.")
    #
    #      expect(@@russian.translate(
    #                      '{actor} loves {target}.', nil,
    #                      :actor => {:object => actor, :attribute => 'name'},
    #                      :target => {:object => target, :attribute => 'name'})
    #      ).to eq("Таня любит Михаила.")
    #
    #      expect(@@russian.translate(
    #                      '{actor} saw {target} {count||day} ago.', nil,
    #                      :actor => {:object => actor, :attribute => 'name'},
    #                      :target => {:object => target, :attribute => 'name'},
    #                      :count => 2)
    #      ).to eq("Таня видела Михаила 2 дня назад.")
    #
    #      expect(@@russian.translate(
    #                      '{actor} saw {target} {count||day} ago.', nil,
    #                      :actor => {:object => target, :attribute => 'name'},
    #                      :target => {:object => actor, :attribute => 'name'},
    #                      :count => 2)
    #      ).to eq("Михаил видел Таню 2 дня назад.")
    #
    #    end
    #
    #    # trn = @@russian.translate("{count||message}", nil, {:count => 1})
    #    # expect(trn).to eq("1 сообщение")
    #  end
    #
  end
end