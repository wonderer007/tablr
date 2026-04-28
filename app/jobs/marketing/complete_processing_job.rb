module Marketing
  class CompleteProcessingJob < ApplicationJob
    include Marketing::CompanyProcessing

    queue_as :default

    def perform(company_id)
      company = Marketing::Company.find(company_id)
      process_company(company)
    end
  end
end
