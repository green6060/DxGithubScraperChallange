class AnalyticsController < ApplicationController
  def dashboard
    @date_range = params[:date_range] || '30_days'
    @organization = params[:organization] || 'vercel'
    
    begin
      @analytics = Analytics::DataAnalysisService.generate_report(
        organization: @organization,
        date_range: @date_range
      )
    rescue => e
      @error_message = "Analytics generation failed: #{e.message}"
      @error_type = 'analytics_error'
    end
  end

  def export
    @date_range = params[:date_range] || '30_days'
    @organization = params[:organization] || 'vercel'
    @format = params[:format] || 'json'
    
    begin
      @analytics = Analytics::DataAnalysisService.generate_report(
        organization: @organization,
        date_range: @date_range
      )
      
      respond_to do |format|
        format.json { render json: @analytics }
        format.csv { send_data generate_csv(@analytics), filename: "github_analytics_#{@organization}_#{@date_range}.csv" }
      end
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def generate_csv(analytics)
    require 'csv'
    
    CSV.generate do |csv|
      # Overview section
      csv << ['Section', 'Metric', 'Value']
      csv << ['Overview', 'Total Repositories', analytics[:overview][:total_repositories]]
      csv << ['Overview', 'Total Pull Requests', analytics[:overview][:total_pull_requests]]
      csv << ['Overview', 'Total Reviews', analytics[:overview][:total_reviews]]
      csv << ['Overview', 'Total Users', analytics[:overview][:total_users]]
      csv << ['Overview', 'Active Contributors', analytics[:overview][:active_contributors]]
      
      # Repository analysis
      csv << ['Repositories', 'Public Count', analytics[:repository_analysis][:public_count]]
      csv << ['Repositories', 'Private Count', analytics[:repository_analysis][:private_count]]
      csv << ['Repositories', 'Active Count', analytics[:repository_analysis][:active_count]]
      csv << ['Repositories', 'Archived Count', analytics[:repository_analysis][:archived_count]]
      
      # Pull request analysis
      csv << ['Pull Requests', 'Open Count', analytics[:pull_request_analysis][:open_count]]
      csv << ['Pull Requests', 'Closed Count', analytics[:pull_request_analysis][:closed_count]]
      csv << ['Pull Requests', 'Merged Count', analytics[:pull_request_analysis][:merged_count]]
      csv << ['Pull Requests', 'Merge Rate', "#{(analytics[:pull_request_analysis][:merge_rate] * 100).round(1)}%"]
      
      # User analysis
      csv << ['Users', 'PR Authors', analytics[:user_analysis][:pr_authors]]
      csv << ['Users', 'Reviewers', analytics[:user_analysis][:reviewers]]
      csv << ['Users', 'With Profiles', analytics[:user_analysis][:users_with_profiles]]
    end
  end
end
