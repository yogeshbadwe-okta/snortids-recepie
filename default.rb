directory "/usr/local/lib/snort_dynamicrules"
directory "/etc/snort/"
directory "/etc/snort/rules"
package "flex"
package "gcc"
package "bison"
package "zlib"
package "zlib-devel"
package "libpcap"
package "libpcap-devel"
package "pcre"
package "pcre-devel"
package "wget"
package "tcpdump"

remote_file "libdnet.rpm" do
        source "http://dl.marmotte.net/rpms/redhat/el6/x86_64/libdnet-1.12-6.el6/libdnet-1.12-6.el6.x86_64.rpm"
        action :create_if_missing
end

package "libdnet" do
        source "/libdnet.rpm"
        action :install
end

remote_file "libdnet-devel.rpm" do
        source "ftp://ftp.univie.ac.at/systems/linux/fedora/epel/6/x86_64/libdnet-devel-1.12-6.el6.x86_64.rpm"
        action :create_if_missing
end

package "libdnet-devel.rpm" do
        source "/libdnet-devel.rpm"
        action :install
end

execute "shared_libs" do
        command "ldconfig --verbose /usr/lib/"
        action :run
end

####### DAQ Download, unzip and install

remote_file "daq.tar.gz" do
        source "https://www.snort.org/downloads/snort/daq-2.0.2.tar.gz"
        action :create_if_missing
        checksum "865bf9b750a2a2ca632591a3c70b0ea0"
end

bash "install_daq" do
        command "tar -zxvf daq.tar.gz"
        action :run
        cwd 'daq-2.0.2'
        code <<-EOH
        ./configure
        make
        make install
        EOH
end

### Snort download, unzip and install

remote_file "snort.tar.gz" do
        source "https://www.snort.org/downloads/snort/snort-2.9.6.2.tar.gz"
        action :create_if_missing
        checksum "2a0e89a48260e45f932af94c0ebb330e"
end

bash "install_snort" do
        command "tar -zxvf snort.tar.gz"
        action :run
        cwd 'snort-2.9.6.2'
        code <<-EOH
        ./configure --enable-sourcefire --enable-non-either-decoder --enable-large-pcap
        make
        make install
        EOH
end

### Get Snort rules and deploy

remote_file "snort_rules.tar.gz" do
        source "http://www.snort.org/rules/snortrules-snapshot-2962.tar.gz?oinkcode=2aec6e6ed623c0b1ebf84967f01ec3ce263231c6"
        action :create
end


bash "deploy_rules" do
        command "tar -zxvoC /etc/snort/ -f /snort_rules.tar.gz"
        action :run
        cwd '/etc/snort/'
        code <<-EOH
        cp /snort-2.9.6.2/etc/* .
        touch /etc/snort/rules/white_list.rules /etc/snort/rules/black_list.rules
        EOH
end

#### Update snort.conf with path to rule file etc

ruby_block "conf_write" do
        block do
                file = Chef::Util::FileEdit.new("/etc/snort/snort.conf")
                file.search_file_replace("var RULE_PATH ../rules", "var RULE_PATH /etc/snort/rules/")
                file.search_file_replace("var SO_RULE_PATH ../so_rules", "var SO_RULE_PATH /etc/snort/rules/so_rules")
                file.search_file_replace("var PREPROC_RULE_PATH ../preproc_rules", "var PREPROC_RULE_PATH /etc/snort/rules/preproc_rules")
                file.search_file_replace("var WHITE_LIST_PATH ../rules", "var WHITE_LIST_PATH /etc/snort/rules")
                file.search_file_replace("var BLACK_LIST_PATH ../rules", "var BLACK_LIST_PATH /etc/snort/rules")
                file.write_file
        end
end
