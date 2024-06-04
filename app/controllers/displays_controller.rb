class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    render "thirteen", locals: {view_object: DisplayContent.new.call}
  end

  def mira
    @refresh = true

    # :nocov:
    begin
      render "mira", locals: {view_object: DisplayContent.new.call}
    rescue => e
      Rails.logger.error("listing #{Thread.list.count} threads:")
      Thread.list.each_with_index do |t,i|
         Rails.logger.error("---- thread #{i}: #{t.inspect}")
         Rails.logger.error(t.backtrace.take(5))
      end

      stats = ActiveRecord::Base.connection_pool.stat
      Rails.logger.error("Connection Pool Stats #{stats.inspect}")

      Rails.logger.error("Render error: " + e.message + e.backtrace.join("\n"))

      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
    # :nocov:
  end
end
