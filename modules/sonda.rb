#Sonda Functionalities.
#Author: Samur Araujo
#Date: 10 June 2012.
#License: Sonda is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
require 'logger'
require 'optparse'
require 'optparse/uri'

options = {}

options = {   
"transitionupdate".to_sym => 'false',
"globalrecall".to_sym => 'true',
"aligner".to_sym => 'HierarchicalClusterAligner',
"ranker".to_sym =>'TimeBasedTransitionRanking',
"selector".to_sym =>'DecisionTreeSelectionAlgorithm',
"searcher".to_sym =>'BranchAndBound',
"learningpercent".to_sym => 0.20,
"transitionfailurerate".to_sym => 1.0,
"qconly".to_sym => 'false',
}

opts = OptionParser.new do |opts|

  opts.banner = "Usage: serimi.rb [options] \n\nExample of use: \nruby sonda.rb -s http://www4.wiwiss.fu-berlin.de/sider/sparql -t http://dbpedia.org/sparql?default-graph-uri=http://dbpedia.org -c http://www4.wiwiss.fu-berlin.de/sider/resource/sider/drugs \n"

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end
  options[:logfile] = nil
  opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do |file|
    options[:logfile] = file
  end
  options[:source] = nil
  opts.on( '-s URI ', '--source URI (MANDATORY)', String, 'Source Virtuoso sparql endpoint - URI' ) do |uri|
    # raise OptionParser::InvalidArgument, uri + ", not a valid URI."  if !(uri =~ /^http[s]?:\/\//)

    options[:source] = uri
  end
  options[:target] = nil
  opts.on( '-t URI ', '--target URI (MANDATORY)', String, 'Target Virtuoso sparql endpoint - URI' ) do |uri|
    # raise OptionParser::InvalidArgument, uri + ", not a valid URI."  if !(uri =~ /^http[s]?:\/\//)

    options[:target] = uri
  end
  options[:class] = nil
  opts.on( '-c URI ', '--class URI (MANDATORY)',String,  'Source class for interlink - URI' ) do |uri|
    raise OptionParser::InvalidArgument, uri + ", not a valid URI."  if uri == nil || !(uri =~ /^http[s]?:\/\//)

    options[:class] = uri
  end
  options[:output] = "./output.txt"
  opts.on( '-o FILE_NAME', '--output FILE', String, 'Write output to FILE - Default=./output.txt' ) do |file|
    options[:output] = file
  end
   options[:append] = "a"
  opts.on( '-a', '--append-output value', String, 'Append output to FILE - A value: a or w  - Default=w' ) do |file|
    options[:append] = file
  end
  options[:format] = "txt"
  opts.on( '-f', '--output-format value', String, 'Output format: txt, nt. Default=txt' ) do |c|
    options[:format] = c
  end
  options[:chunk] = 150
  opts.on( '-k', '--chunk value', Integer, 'Number of source instances processed per interaction, a value >= 2 - Default=20' ) do |c|
    options[:chunk] = c
  end
   options[:topk] = 0
  opts.on( '-p', '--top k results', Integer, 'Return only Top K results, a value >= 1 - Default=0' ) do |c|
    options[:chunk] = c
  end
  options[:offset] = 0
  opts.on( '-b', '--offset value', Integer, 'Start processing from a specific offset - Default=0' ) do |c|
    options[:offset] = c
  end
  options[:stringthreshold] = 0.7
  opts.on( '-x', '--string-threshold value', Float, 'String distance threshold. A value between (0,1) - Default=0.7' ) do |c|
    options[:stringthreshold] = c
  end
  options[:rdsthreshold] = nil
  opts.on( '-y', '--rds-threshold value', Float, 'RDS threshold. A value between (0,1) - Default=max(media,mean)' ) do |c|
    options[:rdsthreshold] = c
  end
 options[:usepivot] = 'false'
  opts.on( '-u', '--use-pivot value', String, 'Select a pivot to reinvorce the class of interest. A value (false or true) - Default=false' ) do |c|
    options[:usepivot] = c
  end 
 
  options[:logfile] = nil
  opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do |file|
    if file != nil
      $logger =  File.open(file, 'a')
      def puts(str)

        if str.instance_of? Array
          str.each{|x|
            $logger.write(x.to_s)
            $logger.write("\n")
          }
        else
          $logger.write(str.to_s)
          $logger.write("\n")
        end
      # $logger.fsync
      end

    end
  end
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
begin
  opts.parse!
  mandatory = [:source, :class, :target]                                         # Enforce the presence of
  missing = mandatory.select{ |param| options[param].nil? }        # the -t and -f switches
  if not missing.empty?                                            #
    puts "Missing options: #{missing.join(', ')}"                  #
    puts opts                                                  #
    exit                                                           #
  end                                                              #
rescue OptionParser::InvalidOption, OptionParser::MissingArgument      #
  puts $!.to_s                                                           # Friendly output when parsing fails
  puts opts                                                          #
  exit                                                                   #
end                                                                      #
puts "Being verbose" if options[:verbose]
puts "Logging to file #{options[:logfile]}" if options[:logfile]
$current_dir = File.dirname(__FILE__)
 require 'initializer'

 Initializer.new(options)
