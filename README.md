<p align="center">
  <img src="https://avatars0.githubusercontent.com/u/1316274?v=3&s=200">
</p>

TML Library For Ruby
==================
[![Build Status](https://travis-ci.org/translationexchange/tml-ruby.png?branch=master)](https://travis-ci.org/translationexchange/tml-ruby)
[![Coverage Status](https://coveralls.io/repos/translationexchange/tml-ruby/badge.png?branch=master)](https://coveralls.io/r/translationexchange/tml-ruby?branch=master)
[![Dependency Status](https://www.versioneye.com/user/projects/54c1457a6c00352081000416/badge.svg?style=flat)](https://www.versioneye.com/user/projects/54c1457a6c00352081000416)
[![Gem Version](https://badge.fury.io/rb/tml.svg)](http://badge.fury.io/rb/tml)
[![Open Source Helpers](https://www.codetriage.com/translationexchange/tml-ruby/badges/users.svg)](https://www.codetriage.com/translationexchange/tml-ruby)

TML library for Ruby is a set of classes that provide translation functionality for any Ruby based application.
The library uses Translation Markup Language that allows you to encode complex language structures in simple, yet powerful forms.

The library works in conjunctions with TranslationExchange.com service that provides machine and human translations for your application.
In order to use the library, you should sign up at TranslationExchange.com, create a new application and copy the application key and secret.


Rails Integration
==================

If you are planning on using TML in a Rails application, you should use tml-rails gem instead.

https://github.com/translationexchange/tml-rails


Installation
==================

To install the gem, use:

```ssh
gem install tml
```


Registering Your App
===================================

Before you can proceed with the integration, please register with http://translationexchange.com and create a new application.

At the end of the registration process you will be given a key and a secret. You will need to enter them in the initialization function of the TML SDK.



Usage
==================

The library can be invoked from the IRB. To use TML client you must require it, and instantiate the application with the key and secret of your app from translationexchange.com:

```ruby
irb(main)> require 'tml'
irb(main)> app = Tml.session.init({
  key: APP_KEY,
  token: SDK_ACCESS_TOKEN
})
```

Now you can use the application to get any language registered with your app:

```ruby
irb(main)> english = app.language('en-US')
irb(main)> russian = app.language('ru')
irb(main)> spanish = app.language('es')
irb(main)> chinese = app.language('zh')
```

Simple example:

```ruby
irb(main)> english.translate('Hello World')
=> "Hello World"
irb(main)> russian.translate('Hello World')
=> "Привет Мир"
irb(main)> spanish.translate('Hello World')
=> "Hola Mundo"
irb(main)> chinese.translate('Hello World')
=> "你好世界"
```

Using description context:

```ruby
irb(main)> russian.translate('Invite', 'An invitation')
=> "Приглашение"
irb(main)> russian.translate('Invite', 'An action to invite')
=> "Пригласить"
```

Numeric rules with piped tokens:

```ruby
irb(main)> english.translate('You have {count||message}.', :count => 1)
=> "You have 1 message."
irb(main)> english.translate('You have {count||message}.', :count => 2)
=> "You have 2 messages."

irb(main)> russian.translate('You have {count||message}.', :count => 1)
=> "У вас есть 1 сообщение."
irb(main)> russian.translate('You have {count||message}.', :count => 2)
=> "У вас есть 2 сообщения."
irb(main)> russian.translate('You have {count||message}.', :count => 5)
=> "У вас есть 5 сообщений."
```

Gender rules:

```ruby
irb(main)> user = {:gender => :female, :name => "Anna"}
irb(main)> english.translate('{user} updated {user| his, her} profile.', :user => {:object => user, :attribute => :name})
=> "Anna updated her profile."

irb(main)> russian.translate('{user} updated {user| his, her} profile.', :user => {:object => user, :attribute => :name})
=> "Anna обновила свой профиль."

irb(main)> user = {:gender => :male, :name => "Michael"}
irb(main)> english.translate('{user} updated {user| his, her} profile.', :user => {:object => user, :attribute => :name})
=> "Michael updated his profile."

irb(main)> russian.translate('{user} updated {user| his, her} profile.', :user => {:object => user, :attribute => :name})
=> "Michael обновил свой профиль."
```

Gender rules with language cases:

```ruby
irb(main)> actor = {:gender => :female, :name => "Анна"}
irb(main)> target = {:gender => :male, :name => "Михаил"}
irb(main)> russian.translate('{actor} sent {target} a gift.', :actor => {:object => actor, :attribute => :name}, :target => {:object => target, :attribute => :name})
=> "Анна послала подарок Михаилу."
irb(main)> russian.translate('{actor} sent {target} a gift.', :actor => {:object => target, :attribute => :name}, :target => {:object => actor, :attribute => :name})
=> "Михаил послал подарок Анне."
```

Decoration tokens:

```ruby
irb(main)> english.translate("[bold: This text] should be bold", :bold => lambda{|text| "<strong>#{text}</strong>"})
=> "<strong>This text</strong> should be bold"
irb(main)> russian.translate("[bold: This text] should be bold", :bold => lambda{|text| "<strong>#{text}</strong>"})
=> "<strong>Этот текст</strong> должны быть жирным"
```

Nested decoration tokens:

```ruby
irb(main)> english.translate("[bold: Bold text [italic: with italic text]] together", :bold => "<b>{$0}</b>", :italic => "<i>{$0}</i>")
=> "<b>Bold text <i>with italic text</i></b> together"
irb(main)> russian.translate("[bold: Bold text [italic: with italic text]] together", :bold => "<b>{$0}</b>", :italic => "<i>{$0}</i>")
=> "<b>Жирный текст <i>с курсив</i></b> вместе"
```

Data tokens with decoration tokens together:

```ruby
irb(main)> user = {:gender => :male, :name => "Michael"}
irb(main)> english.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 5, :link => "<a href='url'>{$0}</a>")
=> "<b>Michael</b> received <a href='url'><b>5</b> messages</a>"
irb(main)> russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :bold => "<b>{$0}</b>", :count => 5, :link => "<a href='url'>{$0}</a>")
=> "<b>Michael</b> получил <a href='url'><b>5</b> сообщений</a>"
```

PS. The Russian translation on translationexchange.com could either be provided by a set of 6-9 simple translations for {genders}(male, female, unknown) * count{one, few, many} or by a single advanced translation
in the form of:

```ruby
[bold: {user}] {user| male: получил, female: получила} [link: [bold: {count}] {count| one: сообщение, few: сообщения, other: сообщений}]
```

Or in a simpler form:

```ruby
[bold: {user}] {user| получил, получила} [link: [bold: {count}] {count| сообщение, сообщения, сообщений}]
```

One of the advantages of using TML is the ability to easily switch token values. The above example in a text based email can reuse translations:

```ruby
irb(main)> english.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :count => 1, :bold => "{$0}", :link => "{$0}")
=> "Michael received 1 message"

irb(main)> russian.translate("[bold: {user}] received [link: [bold: {count}] {count|message}]", :user => {:object => user, :attribute => :name}, :count => 1, :bold => "{$0}", :link => "{$0}")
=> "Michael получил 1 сообщение"
```

You should also notice that all of the translation keys you've been using in your experiments will be registered under your application by the translationexchange.com service. You can view them all at:

https://dashboard.translationexchange.com/

If any translation key you've tried to translate was missing a translation, you can manually translate it using the service (with the help of a machine translation suggestion).

```ruby
irb(main)> russian.translate('This is a new phrase without translations')
=> "This is a new phrase without translations"
```

Then without leaving your IRB session, you can call the following method to reset your application cache:

```ruby
irb(main)> app.reset_translation_cache
```

Then you can just rerun the translation method with the missing translation and you should get back the translated value.

```ruby
irb(main)> russian.translate('This is a new phrase without translations')
=> "Это новая фраза без перевода"
```

Links
==================

* Register on TranslationExchange.com: http://translationexchange.com

* Read TranslationExchange's documentation: http://docs.translationexchange.com

* Follow TranslationExchange on Twitter: https://twitter.com/translationx

* Connect with TranslationExchange on Facebook: https://www.facebook.com/translationexchange

* If you have any questions or suggestions, contact us: feedback@translationexchange.com


Copyright and license
==================

Copyright (c) 2017 Translation Exchange, Inc

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
