# models/outgoing_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

# NOTE: The layout for this wraps messages by lines rather than (blank line
# separated) paragraphs, as is the convention for all the other mailers. This
# turned out to fit better with user exepectations when formatting messages.
#
# TODO: The other mail templates are written to use blank line separated
# paragraphs. They could be rewritten, and the wrapping method made uniform
# throughout the application.

class OutgoingMailer < ApplicationMailer
  # Email to public body requesting info
  def initial_request(info_request, outgoing_message)
    @info_request = info_request
    @outgoing_message = outgoing_message
    @contact_email = AlaveteliConfiguration.contact_email
    headers["message-id"] = OutgoingMailer.id_for_message(@outgoing_message)

    mail(from: @outgoing_message.from,
         to: @outgoing_message.to,
         subject: @outgoing_message.subject)
  end

  # Later message to public body regarding existing request
  def followup(info_request, outgoing_message, incoming_message_followup)
    @info_request = info_request
    @outgoing_message = outgoing_message
    @incoming_message_followup = incoming_message_followup
    @contact_email = AlaveteliConfiguration.contact_email
    headers["message-id"] = OutgoingMailer.id_for_message(@outgoing_message)

    mail(from: @outgoing_message.from,
         to: @outgoing_message.to,
         subject: @outgoing_message.subject)
  end

  # TODO: the condition checking valid_to_reply_to? also appears in views/request/_followup.html.erb,
  # it shouldn't really, should call something here.
  # TODO: also OutgoingMessage.get_salutation
  # TODO: these look like they should be members of IncomingMessage, but logically they
  # need to work even when IncomingMessage is nil
  def self.name_and_email_for_followup(info_request, incoming_message_followup)
    if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
      info_request.recipient_name_and_email
    else
      # calling safe_from_name from so censor rules are run
      MailHandler.address_from_name_and_email(incoming_message_followup.safe_from_name,
                                                     incoming_message_followup.from_email)
    end
  end

  # Used in the preview of followup
  def self.name_for_followup(info_request, incoming_message_followup)
    if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
      info_request.public_body.name
    else
      # calling safe_from_name from so censor rules are run
      incoming_message_followup.safe_from_name || info_request.public_body.name
    end
  end

  # Used when making list of followup places to remove duplicates
  def self.email_for_followup(info_request, incoming_message_followup)
    if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
      info_request.recipient_email
    else
      incoming_message_followup.from_email
    end
  end

  # Subject to use for followup
  def self.subject_for_followup(info_request, outgoing_message, options = {})
    if outgoing_message.what_doing == 'internal_review'
      _("Internal review of {{email_subject}}", email_subject: info_request.email_subject_request(html: options[:html]))
    else
      info_request.email_subject_followup(incoming_message: outgoing_message.incoming_message_followup,
                                                 html: options[:html])
    end
  end

  # Whether we have a valid email address for a followup
  def self.is_followupable?(info_request, incoming_message_followup)
    if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
      info_request.recipient_email_valid_for_followup?
    else
      # email has been checked in incoming_message_followup.valid_to_reply_to? above
      true
    end
  end

  # Message-ID to use
  def self.id_for_message(outgoing_message)
    message_id = "ogm-" + outgoing_message.id.to_s
    t = Time.zone.now
    message_id += "+" + format('%08x%05x-%04x', t.to_i, t.tv_usec, rand(0xffff))
    message_id += "@" + AlaveteliConfiguration.incoming_email_domain
    "<" + message_id + ">"
  end
end
