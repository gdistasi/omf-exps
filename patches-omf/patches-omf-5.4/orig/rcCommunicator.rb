#
# Copyright (c) 2006-2010 National ICT Australia (NICTA), Australia
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#
# = rcCommunicator.rb
#
# == Description
#
# This file implements a Publish/Subscribe Communicator for the Node Agent.
# This PubSub communicator is based on XMPP.
# This current implementation uses the library XMPP4R.
#
#
require "omf-common/communicator/omfCommunicator"
require "omf-common/communicator/omfProtocol"
require 'omf-resctl/omf_agent/agentCommands'

#
# This class defines a Communicator entity using the Publish/Subscribe paradigm.
# The Node Agent (NA) aka Resource Controller will use this Communicator to
# send/receive messages to/from the Node Handler (EC) aka Experiment Controller
# This Communicator is based on the Singleton design pattern.
#

class RCCommunicator < OmfCommunicator

  SEND_RETRY_INTERVAL = 5 # in sec
 
  def init(opts)
    super(opts)
    # RC-specific communicator initialisation
    # 0 - set some attributes
    @@myName = opts[:hrn]
    @@sliceID = opts[:sliceID]
    @@expID = nil
    @@myECAddress = nil
    @@myAliases = [@@myName, "*"]
    @@retrySending = false
    @@exp_listening_list = []
    # 1 - Build my address for this slice
    @@myAddr = create_address(:sliceID => @@sliceID,
                              :name => @@myName,
                              :domain => @@domain)
    # 3 - Set my lists of valid commands
    OmfProtocol::EC_COMMANDS.each { |cmd|
      define_valid_command(cmd) { |comm, message|
        AgentCommands.method(cmd.to_s).call(comm, message)
      }
    }
    # 4 - Set my list of own/self commands
    OmfProtocol::RC_COMMANDS.each { |cmd| define_self_command(cmd) }
  end

  def listen_to_group(group)
    addr = create_address(:sliceID => @@sliceID, :expID => @@expID,
                          :domain => @@domain, :name => group)
    add_alias(group)
    success = listen(addr)
    @@exp_listening_list << addr if success
    return success
  end

  def listen_to_experiment(expID)
    addr = create_address(:sliceID => @@sliceID, :expID => expID,
                          :domain => @@domain)
    success = listen(addr)
    if success
      @@expID = expID if success
      @@exp_listening_list << addr
    end
    return success
  end

  def expID 
    return @@expID
  end

  def set_EC_address(ec_address = nil)
    myEC = ec_address ? ec_address : @@myName
    @@myECAddress = create_address(:sliceID => @@sliceID, :expID => @@expID,
                        :domain => @@domain, :name => myEC)
  end

  def send_reply(result, original_request)
    reply = create_message(:cmdtype => result[:success], :target => @@myName,
                           :reason => result[:reason],
                           :message => result[:info])
    reply.merge(original_request)
    reply.merge(result[:extra]) if result[:extra]
    if result[:slice_message]
      send_message(@@myAddr, reply)
    else
      send_message(@@myECAddress, reply)
    end
  end

  #
  # Send a APP or DEV EVENT message to the EC.
  # This is done when an application started on this resource or a device
  # configured on this resource has a new event to share with the EC
  # (e.g. a message coming on standard-out of the appliation)
  # (e.g. a change of configuration for the device)
  #
  # - type = type of the event (:APP_EVENT or :DEV_EVENT)
  # - name = the name of event
  # - id = the id of the application/device issuing this event
  # - info = a String with the new event info
  #
  def send_event(type, name, id, info)
    message = create_message(:cmdtype => type, :target => @@myName,
                             :value => name, :appID => id, :message => info)
    send_message(@@myECAddress, message)
  end

  def join_slice
    # Listen to my address - wait and try again until successfull
    listening = false
    while !listening
      listening = listen(@@myAddr)
      if !listening
        debug "Cannot listen on address: '#{@@myAddr}' - retry in "+
              "#{RETRY_INTERVAL} sec."
        sleep RETRY_INTERVAL
      end
    end
    # Also listen to the generic resource address for this slice
    listening = false
    addr = create_address(:sliceID => @@sliceID, :domain => @@domain)
    while !listening
      listening = listen(addr)
      if !listening
        debug "Cannot listen on address: '#{@@myAddr}' - retry in "+
              "#{RETRY_INTERVAL} sec."
        sleep RETRY_INTERVAL
      end
    end
  end

  def reset
    # Reset all our internal states
    if @@retrySending
      @@retryThread.kill
      @@retryQueue.clear 
      @@retrySending = false
    end
    @@exp_listening_list.each { |addr| leave(addr) }
    @@myECAddress = nil
    @@expID = nil
    @@myAliases = [@@myName, "*"]
    @@exp_listening_list = []
  end

  alias parentSend send_message

  #
  # Allow this communicator to retry sending when it failed to send a message
  # Failed messages are put in a queue, which is processed by a separate thread
  # This is because sending of messages can occur from different threads (e.g.
  # a ExecApp thread running a user app) and we should not block that thread, 
  # while we try to resend 
  #
  def allow_retry
    @@retrySending = true
    @@retryQueue = Queue.new
    @@retryThread = Thread.new {
      while element = @@retryQueue.pop do
        success = false
        while !success do
          success = parentSend(element[:addr], element[:msg])
          if !success 
            warn "Failed to send message, retry in #{SEND_RETRY_INTERVAL}s "+
             "(msg: '#{element[:msg]}')"
            sleep(SEND_RETRY_INTERVAL)
          end
        end
      end
    } 
  end
 
  private

  def send_message(addr, message)
    message.sliceID = @@sliceID
    message.expID = @@expID
    success = super(addr, message)
    if !success && @@retrySending
      @@retryQueue << {:addr => addr, :msg => message}
      return
    end
    warn "Failed to send message! (msg: '#{message}')" if !success
  end

  def dispatch_message(message)
    result = super(message)
    if result && result.kind_of?(Hash)
      send_reply(result, message)
    end
  end

  def valid_message?(message)
    # 1 - Perform common validations among OMF entities
    return false if !super(message)
    # 2 - Perform RC-specific validations
    # - Ignore messages for/from unknown Slice and Experiment ID
    if (message.cmdType != :ENROLL) && (message.cmdType != :RESET) &&
       ((message.sliceID != @@sliceID) || (message.expID != @@expID))
      debug "Ignoring message with unknown slice "+
            "and exp IDs: '#{message.sliceID}' and '#{message.expID}'"
      return false
    end
    # - Ignore commands that are not address to us
    # (There may be multiple space-separated targets)
    dst = message.target.split(' ')
    forMe = false
    dst.each { |t| forMe = true if @@myAliases.include?(t) }
     if !forMe
       debug "Ignoring command with unknown target "+
             "'#{message.target}' - ignoring it!"
       return false
    end
    # Accept this message
    return true
  end

  def add_alias(newAlias)
    if (@@myAliases.index(newAlias) != nil)
      debug("Alias '#{newAlias}' already registered.")
    else
      @@myAliases.insert(0, newAlias)
    end
    debug("Agent names #{@@myAliases.join(', ')}")
  end

end
