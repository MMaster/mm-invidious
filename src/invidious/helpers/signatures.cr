require "http/params"
require "./sig_helper"

class Invidious::DecryptFunction
  @last_update : Time = Time.utc - 42.days
  @last_vid = ""

  def initialize(uri_or_path)
    @client = SigHelper::Client.new(uri_or_path)
    # self.check_update
  end

  def check_update(vid : String)
    now = Time.utc

    # If we have updated in the last 5 seconds and its still the same video id, do nothing
    return if (now - @last_update) < 5.seconds && vid == @last_vid

    LOGGER.debug("Signature: Player might be outdated, updating")
    @client.force_update(vid)
    @last_update = Time.utc
    @last_vid = vid
  end

  def decrypt_nsig(n : String, vid : String) : String?
    self.check_update(vid)
    return @client.decrypt_n_param(n)
  rescue ex
    LOGGER.debug(ex.message || "Signature: Unknown error")
    LOGGER.trace(ex.inspect_with_backtrace)
    return nil
  end

  def decrypt_signature(str : String, vid : String) : String?
    self.check_update(vid)
    return @client.decrypt_sig(str)
  rescue ex
    LOGGER.debug(ex.message || "Signature: Unknown error")
    LOGGER.trace(ex.inspect_with_backtrace)
    return nil
  end

  def get_sts(vid : String) : UInt64?
    self.check_update(vid)
    return @client.get_signature_timestamp
  rescue ex
    LOGGER.debug(ex.message || "Signature: Unknown error")
    LOGGER.trace(ex.inspect_with_backtrace)
    return nil
  end
end
