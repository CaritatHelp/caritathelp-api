class DocController < ApplicationController
  def index
    render :json => create_response(t("doc.response"), 404, t("doc.url"))
  end

  def errors
  end
end
