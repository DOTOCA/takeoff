# = Twitter Boostrap theme for RDoc
#
# Code rewritten by:
#   Atsushi Nagase <a@ngs.io>
#
# Original Authors:
#   James Tucker (aka raggi)
#   Erik Hollensbe <erik@hollensbe.org>
#   Mislav Marohnić <mislav.marohnic@gmail.com>
#   Tony Strauss (http://github.com/DesigningPatterns)
#   Michael Granger <ged@FaerieMUD.org>, who had maintained the original RDoc template

require 'coderay'
require 'coderay/helpers/file_type'
require 'coffee-script'
require 'haml'
require 'rdoc-takeoff/version'
require 'json'
require 'pathname'
require 'rdoc/generator'
require 'rdoc/rdoc'
require 'sass'
require 'active_support/json'

class RDoc::Generator::TakeOff

  LAYOUT           = 'layout.haml'

  CLASS_PAGE       = 'page.haml'
  METHOD_LIST_PAGE = 'method_list.haml'
  FILE_PAGE        = CLASS_PAGE
  SECTIONS_PAGE    = 'sections.haml'

  FILE_INDEX       = 'file_index.haml'
  CLASS_INDEX      = 'class_index.haml'
  METHOD_INDEX     = 'method_index.haml'

  CLASS_DIR        = 'classes'
  FILE_DIR         = 'files'

  INDEX_OUT        = 'index.html'
  FILE_INDEX_OUT   = File.join 'files',   'index.html'
  CLASS_INDEX_OUT  = File.join 'classes', 'index.html'
  METHOD_INDEX_OUT = File.join 'method',  'index.html'

  DESCRIPTION = 'Twitter Bootstrap theme for RDoc'

  class Item
    attr_accessor :title, :url, :entries, :source, :icon

    def initialize(args)
      args.each do |k,v| self.instance_variable_set("@#{k}", v) end
      entries = []
    end
  end

  # EPIC CUT AND PASTE TIEM NAO -- GG
  RDoc::RDoc.add_generator( self )

  def self::for( options )
    new( options )
  end

  def initialize( options )
    @options = options
    @templatedir = Pathname.new(options.template_dir || File.expand_path('../rdoc-takeoff/template_files', __FILE__))

    @files      = nil
    @classes    = nil
    @methods    = nil
    @attributes = nil

    @basedir = Pathname.pwd.expand_path
  end

  def default_values( path )
    {
      stylesheets: %w{
        takeoff
      }.map {|f|outpath(File.join('css', "#{f}.css"), path)},
      mainpage:   outpath('', path),
      files:      @files,
      classes:    @classes,
      methods:    @methods,
      attributes: @attributes,
      options:    @options,
      path:       path
    }

  end

  def generate( top_levels )
    @outputdir = Pathname.new( @options.op_dir ).expand_path( @basedir )

    @files      = top_levels.sort
    @classes    = RDoc::TopLevel.all_classes_and_modules.sort
    @methods    = @classes.map(&:method_list).flatten.sort
    @attributes = @classes.map(&:attributes).flatten.sort

    # Now actually write the output
    write_static_files

    generate_class_files
    generate_file_files
    generate_indexes

  rescue StandardError => err
    p [ err.class.name, err.message, err.backtrace.join("\n  ") ]
    raise
  end

  def write_static_files
    css_dir = outjoin('css')

    [css_dir].each { |dir|
      FileUtils.mkdir dir unless File.directory?(dir)
    }

    File.open(File.join(css_dir, 'takeoff.css'), 'w') { |f|
      f << Sass::Engine.new(File.read(templjoin('css/takeoff.sass'))).to_css
    }

    FileUtils.cp %w{
      css/arrow.png
      css/listitem.png
      css/method.png
      css/source.png
    }.map{|f| templjoin f }, css_dir

  end

  def generate_indexes
    #generate_index(FILE_INDEX_OUT,   FILE_INDEX,   'File')
    #generate_index(CLASS_INDEX_OUT,  CLASS_INDEX,  'Class')
    #generate_index(METHOD_INDEX_OUT, METHOD_INDEX, 'Method')
    generate_index_json
  end

  def generate_index_json
    path = Pathname.new('index.json')

    identifier = File.basename(@options.op_dir)
    title = identifier.sub('-', ' ')

    root = Item.new(:title => title, :entries => [])

    @classes.each do |klass|
      klass_item = Item.new(:title => klass.full_name, :url => '/'+klass.path, :entries => [], :icon => 'c')
      root.entries << klass_item
      
      klass.each_method do |meth|
        klass_item.entries << Item.new(:title => (meth.singleton ? '::' : '') + meth.name, :url => '/'+klass.path+'#'+meth.aref, :icon => 'm')
      end      
    end
    
    root.entries.sort! {|x,y| x.title <=> y.title }

    File.open(path, 'w') do |f|
      f << ActiveSupport::JSON.encode(root)
    end
  end

  def generate_index(outfile, templfile, index_name)
    path = Pathname.new(outfile)
    dir = path.dirname
    unless File.directory? dir
      FileUtils.mkdir_p dir
    end

    values = default_values(path).merge({
      :list_title => "#{index_name} Index"
    })

    index = haml_file(templjoin(templfile))

    File.open(path, 'w') do |f|
      f << with_layout(values) do
        index.to_html(binding, values)
      end
    end
  end

  def generate_file_files

    # FIXME non-Ruby files
    @files.each do |file|
      generate_file_file(file)
      generate_file_file(file, 'index.html') if @options.main_page == file.name
    end
  end

  def generate_file_file(file, path = nil)
    file_page = haml_file(templjoin(FILE_PAGE))
    method_list_page = haml_file(templjoin(METHOD_LIST_PAGE))

    path = Pathname.new(path || file.path)
    values = default_values(path).merge({
      :file => file,
      :entry => file,
      :classmod => nil,
      :title => file.base_name,
      :list_title => nil,
      :description => file.description
    })

    result = with_layout(values) do
      file_page.to_html(binding, :values => values) do
        method_list_page.to_html(binding, values)
      end
    end

    # FIXME XXX sanity check
    dir = path.dirname
    unless File.directory? dir
      FileUtils.mkdir_p dir
    end

    File.open(outjoin(path.to_path), 'w') { |f| f << result }

  end

  def generate_class_files
    class_page       = haml_file(templjoin(CLASS_PAGE))
    method_list_page = haml_file(templjoin(METHOD_LIST_PAGE))
    sections_page    = haml_file(templjoin(SECTIONS_PAGE))
    # FIXME refactor

    @classes.each do |klass|
      outfile = classfile(klass)
      sections = {}
      klass.each_section do |section, constants, attributes|
        method_types = []
        alias_types = []
        klass.methods_by_type(section).each do |type, visibilities|
          visibilities.each do |visibility, methods|
            aliases, methods = methods.partition{|x| x.is_alias_for}
            method_types << ["#{visibility.to_s.capitalize} #{type.to_s.capitalize}", methods.sort] unless methods.empty?
            alias_types << ["#{visibility.to_s.capitalize} #{type.to_s.capitalize}", aliases.sort] unless aliases.empty?
          end
        end
        sections[section] = {:constants=>constants, :attributes=>attributes, :method_types=>method_types, :alias_types=>alias_types}
      end

      path = Pathname.new(klass.path)

      values = default_values(path).merge({
        :file => klass.path,
        :entry => klass,
        :classmod => klass.type,
        :title => klass.full_name,
        :list_title => nil,
        :description => klass.description,
        :sections => sections
      })

      result = with_layout(values) do
        h = {:values => values}
        class_page.to_html(binding, h) do
          method_list_page.to_html(binding, h) + sections_page.to_html(binding, h)
        end
      end

      # FIXME XXX sanity check
      dir = outfile.dirname
      unless File.directory? dir
        FileUtils.mkdir_p dir
      end

      File.open(outfile, 'w') { |f| f << result }
    end
  end

  def with_layout(values)
    layout = haml_file(templjoin(LAYOUT))
    layout.to_html(binding, :values => values) { yield }
  end

  def sanitize_code_blocks(text)
    text.gsub(/<pre>(.+?)<\/pre>/m) do
      code = $1.sub(/^\s*\n/, '')
      indent = code.gsub(/\n[ \t]*\n/, "\n").scan(/^ */).map{ |i| i.size }.min
      code.gsub!(/^#{' ' * indent}/, '') if indent > 0

        "<pre>#{code}</pre>"
    end
  end

  def class_dir
    CLASS_DIR
  end

  def file_dir
    FILE_DIR
  end

  def h(html)
    CGI::escapeHTML(html)
  end

  # XXX may my sins be not visited upon my sons.
  def render_class_tree(entries, from_path, parent=nil)
    namespaces = { }

    entries.sort.inject('') do |out, klass|
      unless namespaces[klass.full_name]
        if parent
          text = '<span class="parent">%s::</span>%s' % [parent.full_name, klass.name]
        else
          text = klass.name
        end

        if klass.document_self
          link = Pathname.new(classfile(klass)).relative_path_from(from_path.dirname)
          out << "<li>#{ link_to(text, link) }</li>"
        end

        subentries = @classes.select { |x| x.full_name[/^#{klass.full_name}::/] }
        subentries.each { |x| namespaces[x.full_name] = true }
        out << render_class_tree(subentries, from_path, klass)

      end

      out
    end
  end

  def build_javascript_search_index(entries)
    'var searchIndex = ' + (entries.map { |entry|
      method_name = entry.name
      module_name = entry.parent_name
      link = [classfile(entry.parent), (entry.aref rescue "method-#{entry.html_name}")].join('#')
      {
        'method' => method_name,
        'module' => module_name,
        'link'   => link
      }
    }.to_json)
  end

  def link_to(text, url = nil, classname = nil, base = nil)
    class_attr = classname ? ' class="%s"' % classname : ''

    if url
        %[<a href="#{base}#{url}"#{class_attr}>#{text}</a>]
    elsif classname
        %[<span#{class_attr}>#{text}</span>]
    else
      text
    end
  end

  # +method_text+ is in the form of "ago (ActiveSupport::TimeWithZone)".
  def link_to_method(entry, url = nil, classname = nil)
    method_name = entry.pretty_name rescue entry.name
    module_name = entry.parent_name rescue entry.name
    link_to %Q(<li><strong>#{h method_name}</strong><small>#{h module_name}</small></li>), url, classname
  end

  def classfile(klass)
    # FIXME sloooooooow
    Pathname.new(File.join(CLASS_DIR, klass.full_name.split('::')) + '.html')
  end

  def outpath( path, from_path )
    Pathname.new(path).relative_path_from(from_path.dirname)
  end

  def outjoin(name)
    File.join(@outputdir, name)
  end

  def templjoin(name)
    File.join(@templatedir, name)
  end

  def haml_file(file)
    Haml::Engine.new(File.read(file))
  end

  def highlighted_code_block(method)
    lang = CodeRay::FileType.fetch(method.file.name, :text, true)
    src = method.token_stream.map(&:text).join

    # from RDoc::Generator::Markup#markup_code
    indent = src.length
    lines = src.lines.to_a
    start = 0
    line_numbers = false
    if src =~ /\A.*#\ *File/i # remove '# File' comment
      line = lines.shift
      line_numbers = @options.line_numbers if line.sub!(/\A(.*)(, line (\d+))/, '\1')
      start = $3.to_i
    end
    lines.each do |line|
      if line =~ /^ *(?=\S)/
        n = $&.length
        indent = n if n < indent
        break if n == 0
      end
    end
    src = lines.join
    src.gsub!(/^#{' ' * indent}/, '') if indent > 0

    CodeRay.highlight(src, lang,
      :line_numbers        => line_numbers ? :table : nil,
      :line_number_anchors => "#{method.aref}-source-",
      :line_number_start   => start
      )
  end
end
