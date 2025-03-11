# frozen_string_literal: true

module Zee
  class Controller
    # Easily define `<meta>` and `<link>` tags. I18n support for descriptions,
    # keywords and titles.
    #
    # > [!NOTE]
    # > This is an opt-in module. To enable it, you must include this module to
    # > your controller, like `include Zee::Controller::Meta`.
    #
    # ```ruby
    # module Controllers
    #   class Base < Zee::Controller
    #     # Include the meta module.
    #     include Zee::Controller::Meta
    #   end
    # end
    # ```
    #
    # Your controller and views have an object called `meta`. You can use it to
    # define meta tags and links. By default, it will include the encoding,
    # language and viewport meta tags.
    #
    # ```html
    # <html>
    #   <head>
    #     <meta charset="utf-8" />
    #     <meta name="language" content="en" />
    #     <meta itemprop="language" content="en" />
    #     <meta name="viewport" content="width=device-width,initial-scale=1" />
    #   </head>
    # </html>
    # ```
    # You can use I18n to define titles, descriptions and keywords. These values
    # will be inferred from the controller and action names. For an action
    # `SiteController#index` you'll need the following translation scope:
    #
    # ```yaml
    # en:
    #   zee:
    #     meta:
    #       title_base: "%{value} • MyApp"
    #
    #       site:
    #         index:
    #           title: "Welcome to MyApp"
    # ```
    #
    # The title without the `base` context can be accessed through
    # `meta.title`.
    #
    # ```erb
    # <%= meta.title %>         // Welcome to MyApp • MyApp
    # <%= meta.title.text %>    // Welcome to MyApp
    # ```
    #
    # You may need to render dynamic values. In this case, you can use the I18n
    # placeholders.
    #
    # ```yaml
    # ---
    # en:
    #   zee:
    #     meta:
    #       title_base: "%{title} • MyCompany"
    #
    #       workshops:
    #         show:
    #           title: "%{name}"
    # ```
    #
    # You can then set dynamic values using the {Meta::Base#[]=}.
    #
    # ```ruby
    # class WorkshopsController < ApplicationController
    #   def show
    #     @workshop = Workshop.find_by_permalink!(params[:permalink])
    #     meta[:name] = @workshop.name
    #   end
    # end
    # ```
    #
    # Some actions are aliased, so you don't have to duplicate the translations:
    #
    # - Action `create` points to `new`
    # - Action `update` points to `edit`
    # - Action `destroy` points to `remove`
    #
    # The same concept is applied to descriptions and keywords.
    #
    # ```yaml
    # ---
    # en:
    #   zee:
    #     meta:
    #       title_base: "%{value} • MyApp"
    #       site:
    #         show:
    #           title: "Show"
    #           description: MyApp is the best way of doing something.
    #           keywords: "myapp, thing, other thing"
    # ```
    #
    # ### Defining base url
    #
    # You can define the base url.
    #
    # ```ruby
    # meta.base "https://example.com/"
    # ```
    #
    # ### Defining meta tags
    #
    # To define other meta tags, you have to use `PageMeta::Base#tag` like the
    # following:
    #
    # ```ruby
    # class Workshops Controller < ApplicationController
    #   def show
    #     @workshop = Workshop.find_by_permalink(params[:permalink])
    #     meta.tag :description, @workshop.description
    #     meta.tag :keywords, @workshop.tags
    #   end
    # end
    # ```
    #
    # > [!NOTE]
    # > The meta tag's content can also be any object that responds to the
    # > method `call`. This way you can lazy evaluate the content.
    #
    # You can define default meta/link tags in a `before_action`:
    #
    # ```ruby
    # class ApplicationController < ActionController::Base
    #   before_action :set_default_meta
    #
    #   private
    #
    #   def set_default_meta
    #     meta.tag :dns_prefetch_control, "http://example.com"
    #     meta.tag :robots, "index, follow"
    #     meta.tag :copyright, "Example Inc."
    #   end
    # end
    # ```
    #
    # Finally, you can define meta tags for Facebook and Twitter:
    #
    # ```ruby
    # # Meta tags for Facebook
    # meta.tag :og, {
    #   image: asset_url("fb.png"),
    #   image_type: "image/png",
    #   image_width: 800,
    #   image_height: 600,
    #   description: @workshop.description,
    #   title: @workshop.name,
    #   url: workshop_url(@workshop)
    # }
    #
    # # Meta tags for Twitter
    # meta.tag :twitter, {
    #   card: "summary_large_image",
    #   title: @workshop.name,
    #   description: @workshop.description,
    #   site: "@howto",
    #   creator: "@fnando",
    #   image: helpers.asset_url(@workshop.cover_image)
    # }
    # ```
    #
    # ### Defining link tags
    #
    # To define link tags, you have to use `PageMeta::Base#link` like the
    # following:
    #
    # ```ruby
    # meta.link :canonical, href: article_url(article)
    # meta.link :last, href: article_url(articles.last)
    # meta.link :first, href: article_url(articles.first)
    # ```
    #
    # The hash can be any of the link tag's attributes. The following example
    # defines the Safari 9 Pinned Tab icon:
    #
    # ```ruby
    # meta.link :mask_icon,
    #           color: "#4078c0",
    #           href: asset_url("mask_icon.svg")
    # ```
    #
    # ### Rendering the elements
    #
    # To render all tags, just do something like this:
    #
    # ```erb
    # <!DOCTYPE html>
    # <html lang="en">
    #   <head>
    #     <%= meta.render %>
    #   </head>
    #   <body>
    #     <%= yield %>
    #   </body>
    # </html>
    # ```
    #
    # #### Rendering titles and descriptions
    #
    # You may want to render title and description on your page. Use something
    # like this:
    #
    # ```erb
    # <h1><%= meta.title.text %></h1>
    # <p><%= meta.description.text %></p>
    # ```
    #
    # If your description contains HTML, you can use
    # `meta.description.html` instead.
    module Meta
      def self.included(controller)
        controller.expose :meta
      end

      private def meta
        @meta ||= Meta::Base.new(controller_name:, action_name:, helpers:)
      end
    end
  end
end
