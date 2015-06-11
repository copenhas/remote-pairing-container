FROM ubuntu:14.04.2
MAINTAINER Sean Copenhaver <sean.copenhaver@gmail.com>

WORKDIR /root

COPY ssh_key_adder.rb /root/ssh_key_adder.rb
COPY tmux.conf /root/.tmux.conf
COPY ctags /root/.ctags
COPY zshrc /root/.zshrc

ENV SHELL=/usr/bin/zsh
ENV TERM=xterm-256color

# Start by changing the apt output, as stolen from Discourse's Dockerfiles.
RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections && \
  apt-get update && \
# install packages needed
  apt-get install -y \
  build-essential \
  automake \
  cmake \
  ctags \
  man \
  ack-grep \
  llvm \
  git \
  vim \
  curl \
  tmux \
  ssh \
  zsh \
  ruby \
  python-dev


# zsh - ignoring any return status from it since it returns '1' but succeeded anyway
RUN chsh -s /usr/bin/zsh root && \
  curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh || true && \

# setup vim, plugins still have to be installed and youcompleteme compiled manually
  git clone https://github.com/copenhas/dotvim.git ./code/dotvim && \
  ln -s ./code/dotvim/vim .vim && \
  ln -s ./code/dotvim/vimrc .vimrc && \
  git clone https://github.com/gmarik/vundle.git ./code/dotvim/vim/bundle/vundle && \

# Fix for occasional errors in perl stuff (git, ack) saying that locale vars
# aren't set.
  locale-gen en_US en_US.UTF-8 && dpkg-reconfigure locales && \

# Setup everything for starting SSH
  gem install github-auth && \
  chmod +x /root/ssh_key_adder.rb && \
  mkdir /var/run/sshd && \
  echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config

# Expose SSH
EXPOSE 22

# When the container is started we want to
# install the SSH keys of ENV-configured GitHub users before running the SSH
# server process. See README for SSH instructions.
CMD /root/ssh_key_adder.rb && /usr/sbin/sshd -D

