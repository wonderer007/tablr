module Marketing
  class ScheduleOutreachJob < ApplicationJob
    queue_as :default

    def perform
      company = next_company_for_outreach
      return unless company

      Rails.logger.info("[Marketing::ScheduleOutreachJob] Enqueuing CompleteProcessingAndEmailJob for company_id=#{company.id}")
      Marketing::CompleteProcessingAndEmailJob.perform_later(company.id)
    end

    private

    def next_company_for_outreach
      ready_ids = Marketing::Company
                    .ready_for_outreach
                    .where(flagged: false)
                    .pluck(:id)

      return if ready_ids.empty?

      Marketing::Company
        .where(id: ready_ids)
        .left_joins(:marketing_contacts)
        .group("marketing_companies.id")
        .order(Arel.sql("COUNT(marketing_contacts.id) ASC"))
        .first
    end
  end
end
