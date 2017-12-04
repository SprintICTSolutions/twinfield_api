module Twinfield
  module Create
    class Invoice
      attr_accessor  :code, :number, :currency, :date, :duedate, :invoicenumber, :invoice_lines, :destiny, :raisewarning, :autobalancevat

      def destiny
        @destiny || 'temporary'
      end
  
      def raisewarning
        @raisewarning || false
      end
  
      def autobalancevat
        @autobalancevat || true
      end
  
      def initialize(hash={})
        # Escape all the things.
        hash.each do |k,v|
          val = if v.is_a?(String)
            CGI.escapeHTML(v)
          elsif v.is_a?(Hash)
            v.inject({}) { |h, (k1, v1)| h[k1] = CGI.escapeHTML(v1); h }
          else
            v
          end

          send("#{k}=", val)
        end
      end

      def generate_lines
        xml_lines = invoice_lines.map do |line|
          %Q(
            <line type="#{line[:type]}" id="#{line[:id]}" >
              <dim1>#{line[:dim1]}</dim1>
              <dim2>#{line[:dim2]}</dim2>
              <dim3>#{line[:dim3]}</dim3>
              <value>#{line[:value]}</value>
              #{ "<vatvalue>#{line[:vatvalue]}</vatvalue>" if line[:vatvalue] }
              <debitcredit>#{line[:debitcredit]}</debitcredit>
              <description>#{CGI.escapeHTML(line[:description]) if line[:description]}</description>
              #{ "<vatcode>#{line[:vatcode]}</vatcode>" if line[:vatcode] }
              #{ "<performancetype>#{line[:performancetype]}</performancetype>" if line[:performancetype] }
              #{ "<performancedate>#{line[:performancedate].strftime("%Y%m%d")}</performancedate>" if line[:performancedate] }
            </line>
          )
        end

        xml_lines.join("")
      end

      def save
        response = Twinfield::Process.request do
          %Q(
            <transaction destiny="#{destiny}" raisewarning="#{raisewarning}" autobalancevat="#{autobalancevat}">
              <header>
                <code>#{code}</code>
                #{"<number>#{number}</number>" if number }
                <currency>#{currency}</currency>
                <date>#{date.strftime("%Y%m%d")}</date>
                <duedate>#{duedate.strftime("%Y%m%d")}</duedate>
                <invoicenumber>#{invoicenumber}</invoicenumber>
                <office>#{Twinfield.configuration.company}</office>
              </header>
              <lines>
                #{generate_lines}
              </lines>
            </transaction>
          )
        end

        xml = Nokogiri::XML(response.body[:process_xml_string_response][:process_xml_string_result])

        if xml.at_css("transaction").attributes["result"].value == "1"
          return {
            code: invoicenumber,
            status: 1,
            twinfield_number: xml.at_css("number").content
          }
        else
          return {
            code: invoicenumber,
            status: 0,
            messages: xml.css("[msg]").map{ |x| x.attributes["msg"].value }
          }
        end
      end
    end
  end
end