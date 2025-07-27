namespace :email_reports do
  desc "Send weekly restaurant performance reports to all users"
  task send_weekly: :environment do
    puts "Sending weekly restaurant performance reports..."
    
    end_date = Date.current
    start_date = end_date - 1.week
    
    Place.includes(:users).find_each do |place|
      next if place.users.empty?
      
      place.users.each do |user|
        begin
          RestaurantReportMailer.periodic_report(
            user, 
            place, 
            start_date, 
            end_date, 
            'weekly'
          ).deliver_now
          
          puts "✅ Sent weekly report to #{user.email} for #{place.name}"
        rescue => e
          puts "❌ Failed to send weekly report to #{user.email} for #{place.name}: #{e.message}"
        end
      end
    end
    
    puts "Weekly reports sending completed!"
  end

  desc "Send bi-weekly restaurant performance reports to all users"
  task send_biweekly: :environment do
    puts "Sending bi-weekly restaurant performance reports..."
    
    end_date = Date.current
    start_date = end_date - 2.weeks
    
    Place.includes(:users).find_each do |place|
      next if place.users.empty?
      
      place.users.each do |user|
        begin
          RestaurantReportMailer.periodic_report(
            user, 
            place, 
            start_date, 
            end_date, 
            'bi-weekly'
          ).deliver_now
          
          puts "✅ Sent bi-weekly report to #{user.email} for #{place.name}"
        rescue => e
          puts "❌ Failed to send bi-weekly report to #{user.email} for #{place.name}: #{e.message}"
        end
      end
    end
    
    puts "Bi-weekly reports sending completed!"
  end

  desc "Send monthly restaurant performance reports to all users"
  task send_monthly: :environment do
    puts "Sending monthly restaurant performance reports..."
    
    end_date = Date.current
    start_date = end_date - 1.month
    
    Place.includes(:users).find_each do |place|
      next if place.users.empty?
      
      place.users.each do |user|
        begin
          RestaurantReportMailer.periodic_report(
            user, 
            place, 
            start_date, 
            end_date, 
            'monthly'
          ).deliver_now
          
          puts "✅ Sent monthly report to #{user.email} for #{place.name}"
        rescue => e
          puts "❌ Failed to send monthly report to #{user.email} for #{place.name}: #{e.message}"
        end
      end
    end
    
    puts "Monthly reports sending completed!"
  end

  desc "Send custom date range report for a specific place"
  task :send_custom, [:place_id, :start_date, :end_date, :report_type] => :environment do |t, args|
    place = Place.find(args[:place_id])
    start_date = Date.parse(args[:start_date])
    end_date = Date.parse(args[:end_date])
    report_type = args[:report_type] || 'custom'
    
    puts "Sending custom report for #{place.name} (#{start_date} to #{end_date})..."
    
    place.users.each do |user|
      begin
        RestaurantReportMailer.periodic_report(
          user,
          place,
          start_date,
          end_date,
          report_type
        ).deliver_now
        
        puts "✅ Sent custom report to #{user.email}"
      rescue => e
        puts "❌ Failed to send custom report to #{user.email}: #{e.message}"
      end
    end
    
    puts "Custom report sending completed!"
  end

  desc "Preview report for a specific place (doesn't send email)"
  task :preview, [:place_id] => :environment do |t, args|
    place = Place.find(args[:place_id])
    user = place.users.first
    
    unless user
      puts "❌ No users found for place #{place.name}"
      exit
    end
    
    end_date = Date.current
    start_date = end_date - 1.week
    
    puts "="*60
    puts "PREVIEW: Weekly Report for #{place.name}"
    puts "="*60
    puts "User: #{user.full_name} (#{user.email})"
    puts "Date Range: #{start_date} to #{end_date}"
    puts "="*60
    
    # Set tenant context and generate preview data
    ActsAsTenant.with_tenant(place) do
      mailer = RestaurantReportMailer.new
      
      # Access private method for preview
      mailer.instance_variable_set(:@place, place)
      mailer.instance_variable_set(:@start_date, start_date)
      mailer.instance_variable_set(:@end_date, end_date)
      
      report_data = mailer.send(:generate_report_data)
      
      puts "📊 OVERVIEW:"
      puts "  Total Reviews: #{report_data[:total_reviews]}"
      puts "  Average Rating: #{report_data[:average_rating]}/5"
      puts "  Total Complaints: #{report_data[:complaints_data][:total_count]}"
      puts "  Total Suggestions: #{report_data[:suggestions_data][:total_count]}"
      puts
      
      puts "😊 SENTIMENT:"
      puts "  Positive: #{report_data[:sentiment_stats][:positive]} (#{report_data[:sentiment_stats][:positive_percentage]}%)"
      puts "  Neutral: #{report_data[:sentiment_stats][:neutral]} (#{report_data[:sentiment_stats][:neutral_percentage]}%)"
      puts "  Negative: #{report_data[:sentiment_stats][:negative]} (#{report_data[:sentiment_stats][:negative_percentage]}%)"
      puts
      
      puts "⭐ RATINGS:"
      puts "  Food: #{report_data[:rating_stats][:food_rating]}/5"
      puts "  Service: #{report_data[:rating_stats][:service_rating]}/5"
      puts "  Atmosphere: #{report_data[:rating_stats][:atmosphere_rating]}/5"
      puts
      
      if report_data[:complaints_data][:top_complaints].any?
        puts "⚠️ TOP COMPLAINTS:"
        report_data[:complaints_data][:top_complaints].each_with_index do |complaint, index|
          puts "  #{index + 1}. #{complaint[:text]} (#{complaint[:count]} mentions)"
        end
        puts
      end
      
      if report_data[:suggestions_data][:top_suggestions].any?
        puts "💡 TOP SUGGESTIONS:"
        report_data[:suggestions_data][:top_suggestions].each_with_index do |suggestion, index|
          puts "  #{index + 1}. #{suggestion[:text]} (#{suggestion[:count]} mentions)"
        end
        puts
      end
      
      if report_data[:top_dishes].any?
        puts "🍽️ TOP DISHES:"
        report_data[:top_dishes].each_with_index do |dish, index|
          puts "  #{index + 1}. #{dish[:name]} (#{dish[:mentions]} mentions)"
        end
        puts
      end
      
      puts "🏷️ KEYWORDS BY CATEGORY:"
      report_data[:keywords_by_category].each do |category|
        puts "  #{category[:name].upcase} (#{category[:total_keywords]} keywords):"
        if category[:top_positive].any?
          puts "    ✅ Positive: #{category[:top_positive].map { |k| "#{k[:name]} (#{k[:count]})" }.join(', ')}"
        end
        if category[:top_negative].any?
          puts "    ❌ Negative: #{category[:top_negative].map { |k| "#{k[:name]} (#{k[:count]})" }.join(', ')}"
        end
        puts
      end
    end
    
    puts "="*60
    puts "Preview completed! Use send_weekly/send_monthly tasks to actually send emails."
  end
end

# Usage examples:
#
# Send weekly reports to all users:
# rake email_reports:send_weekly
#
# Send monthly reports to all users:
# rake email_reports:send_monthly
#
# Send bi-weekly reports to all users:
# rake email_reports:send_biweekly
#
# Send custom date range report for a specific place:
# rake email_reports:send_custom[1,"2024-01-01","2024-01-31","january_summary"]
#
# Preview report for a specific place:
# rake email_reports:preview[1] 