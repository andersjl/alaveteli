##
# Controller responsible for handling Alaveteli Pro InfoRequest classification
#
class AlaveteliPro::ClassificationsController < AlaveteliPro::BaseController
  include Classifiable

  def create
    new_status = info_request_params[:described_state]
    @info_request.set_described_state(new_status, current_user)
    flash[:notice] = _('Your request has been updated!')
    redirect_to show_alaveteli_pro_request_path(
      url_title: @info_request.url_title
    )
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(url_title: params[:url_title])
  end

  def authorise_info_request
    authorize! :update_request_state, @info_request
  end

  def info_request_params
    params.require(:info_request).permit(:described_state)
  end
end
