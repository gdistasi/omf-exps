#
# Copyright (c) 2006-2009 National ICT Australia (NICTA), Australia
#
# Copyright (c) 2004-2009 WINLAB, Rutgers University, USA
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
# = virtualmesh.rb
#
# == Description
#
# This file defines the class AtherosDevice which is a sub-class of 
# WirelessDevice.
#
require 'omf-resctl/omf_driver/wireless'

#
# This class represents an Atheros device
#
class VirtualMeshDevice < WirelessDevice

  #
  # Create and set up a new VirtualMesh device instance
  #
  def initialize(logicalName, deviceName)
    super(logicalName, deviceName)
    @driver = ''
    @iwconfig = '/sbin/iwconfig'
    @ifconfig = '/sbin/ifconfig'
    @mode='sta'
  end

  #no module to load
  def activate()

  end
  #
  # Return the specific command required to configure a given property of this 
  # device. When a property does not exist for this device, check if it does 
  # for its super-class.
  #
  # - prop = the property to configure
  # - value = the value to configure that property to
  #
  def getConfigCmd(prop, value)

   baseDevice = case
     when @deviceName == 'wlan0' : 'phy0'
     when @deviceName == 'wlan1' : 'phy1'
    else
     raise "Unknown device name '#{@deviceName}'."
   end


    @propertyList[prop.to_sym] = value
    case prop
      when 'type'
        # 'value' defines type of operation
        type = case
          when value == 'a' : 1
          when value == 'b' : 2
          when value == 'g' : 3
          else
            raise "Unknown type. Should be 'a', 'b', or 'g'."
        end
        #return "#{@iwpriv} #{@deviceName} mode #{type}"
	return "/bin/true"
	
      when "mode"
        mode = case
          when value == 'master' : 'ap'
          when value == 'Master' : 'ap'
          when value == 'managed' : 'sta'
          when value == 'Managed' : 'sta'
          when value == 'adhoc' : 'ad-hoc'
          when value == 'Ad-Hoc' : 'ad-hoc'
          when value == 'adhoc' : 'ad-hoc'
          when value == 'AdHoc' : 'ad-hoc'
          when value == 'monitor' : 'monitor'
          when value == 'Monitor' : 'monitor'
	  when value == 'mesh' : 'mesh'
          else
            raise "Unknown mode '#{value}'. Should be 'master', 'managed', or 'adhoc'."
        end

	@mode=mode
	
	if mode=="mesh"
	  return "/bin/false"
	else
	  return "#{@iwconfig} #{@deviceName} mode #{mode} "
	end

     when "essid"
        @essid = value
        return "#{@iwconfig} #{@deviceName} essid #{@essid}"

     when "rts"
        return "#{@iwconfig} #{baseDevice} rts #{value}"

     when "rate"
        #return "#{@iw} dev #{@deviceName} set bitrates legacy-2.4 #{value}"
	return "#{@iwconfig} #{@deviceName} rate #{value}"
       
      when "frequency"
        return "#{@iwconfig} #{@deviceName} freq #{value}"

     when "channel"
	if @mode=='mesh'       
	  return "/bin/false"
	else
	  #the first channel in VirtualMesh is 0
	  return "#{@iwconfig} #{@deviceName} channel #{Integer(value)-1}"
	end
	  
     when "tx_power"
        return "#{@iwconfig} #{@deviceName} txpower #{value}"

     when "mtu"
        return "#{@ifconfig} #{@deviceName} mtu #{value}"
	 
     when "ap"
        return "#{@iwconfig} #{@deviceName} ap #{value}"
	
     when "txqueuelen"
        return "#{@ifconfig} #{@deviceName} txqueuelen #{value}"

    end
    super
  end

  def get_property_value(prop)
    # Note: for now we are returning values set by a CONFIGURE command
    # when refactoring the device handling scheme, we may want to query
    # the system here to find out the real value of the property
    result = super(prop)
    result = @propertyList[prop] if !result
    return result 
  end

end
