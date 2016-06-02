# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: incoming_messages
#
#  id                             :integer          not null, primary key
#  info_request_id                :integer          not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  raw_email_id                   :integer          not null
#  cached_attachment_text_clipped :text
#  cached_main_body_text_folded   :text
#  cached_main_body_text_unfolded :text
#  subject                        :text
#  mail_from_domain               :text
#  valid_to_reply_to              :boolean
#  last_parsed                    :datetime
#  mail_from                      :text
#  sent_at                        :datetime
#  prominence                     :string(255)      default("normal"), not null
#  prominence_reason              :text
#

FactoryGirl.define do

  factory :incoming_message do
    info_request
    raw_email
    last_parsed { 1.week.ago }
    sent_at { 1.week.ago }

    after(:create) do |incoming_message, evaluator|
      create(:body_text,
             :incoming_message => incoming_message,
             :url_part_number => 1)

      incoming_message.raw_email.incoming_message = incoming_message
      incoming_message.raw_email.data = "somedata"
    end

    factory :plain_incoming_message do
      last_parsed { nil }
      sent_at { nil }
      after(:create) do |incoming_message, evaluator|
        data = load_file_fixture('incoming-request-plain.email')
        data.gsub!('EMAIL_FROM', 'Bob Responder <bob@example.com>')
        incoming_message.raw_email.data = data
        incoming_message.raw_email.save!
      end
    end

    factory :incoming_message_with_html_attachment do
      after(:create) do |incoming_message, evaluator|
        FactoryGirl.create(:html_attachment,
                           :incoming_message => incoming_message,
                           :url_part_number => 2)
      end
    end

    factory :incoming_message_with_attachments do
      # foi_attachments_count is declared as an ignored attribute and available in
      # attributes on the factory, as well as the callback via the evaluator
      transient do
        foi_attachments_count 2
      end

      # the after(:create) yields two values; the incoming_message instance itself and the
      # evaluator, which stores all values from the factory, including ignored
      # attributes;
      after(:create) do |incoming_message, evaluator|
        evaluator.foi_attachments_count.times do |count|
          create(:pdf_attachment,
                 :incoming_message => incoming_message,
                 :url_part_number => count+2)
        end
      end
    end
  end

end
