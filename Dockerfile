FROM rhscl/s2i-base-rhel7

# RHSCL rh-nginx18 image.
#
# Volumes:
#  * /var/opt/rh/rh-nginx18/log/nginx/ - Storage for logs

EXPOSE 8080
EXPOSE 8443

LABEL io.k8s.description="Platform for running AngularJS on nginx" \
      io.k8s.display-name="Nginx 1.8" \
      io.openshift.expose-services="8080:http" \
      io.openshift.expose-services="8443:https" \
      io.openshift.tags="builder,nginx,rh-nginx18" \
      BZComponent="rh-nginx18-docker" \
      Name="rhscl_beta/nginx-18-rhel7" \
      Version="1.8" \
      Release="12" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i \
      io.s2i.scripts-url=image:///usr/libexec/s2i \
      Architecture="x86_64"

ENV NGINX_CONFIGURATION_PATH=/opt/app-root/etc/nginx.d
ENV NGINX_DEFAULT_SERVER_CONFIGURATION_PATH=/opt/app-root/etc/nginx.default.d
ENV NGINX_ENV_SERVER_CONFIGURATION_PATH=/opt/app-root/etc/nginx.env.d

RUN INSTALL_PKGS="rh-nodejs4 rh-nodejs4-npm rh-nodejs4-nodejs-nodemon ruby" && \
    yum install -y --setopt=tsflags=nodocs \
    --enablerepo rhel-server-rhscl-7-rpms  \
    --enablerepo rhel-7-server-optional-rpms \
    $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y

RUN yum install -y yum-utils gettext hostname && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms && \
    yum-config-manager --enable rhel-7-server-ose-3.0-rpms && \
    yum install -y --setopt=tsflags=nodocs nss_wrapper && \
    yum install -y --setopt=tsflags=nodocs bind-utils rh-nginx18 rh-nginx18-nginx && \
    yum clean all -y 

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Each language image can have 'contrib' a directory with extra files needed to
# run and build the applications.
COPY ./contrib/ /opt/app-root

#RUN sed -i -f /opt/app-root/nginxconf.sed /etc/opt/rh/rh-nginx18/nginx/nginx.conf 

COPY ./contrib/nginx.conf /etc/opt/rh/rh-nginx18/nginx/nginx.conf 

# In order to drop the root user, we have to make some directories world
# writeable as OpenShift default security model is to run the container under
# random UID.
RUN mkdir -p /opt/app-root/etc/nginx.d/ && \
    chmod -R a+rwx /opt/app-root/etc && \
    chmod -R a+rwx /var/opt/rh/rh-nginx18 && \
    chown -R 1001:0 /opt/app-root && \
    chown -R 1001:0 /var/opt/rh/rh-nginx18

USER 1001

VOLUME ["/opt/rh/rh-nginx18/root/usr/share/nginx/html"]
VOLUME ["/var/opt/rh/rh-nginx18/log/nginx/"]

ENV BASH_ENV=/opt/app-root/etc/scl_enable \
    ENV=/opt/app-root/etc/scl_enable \
    PROMPT_COMMAND=". /opt/app-root/etc/scl_enable"

CMD $STI_SCRIPTS_PATH/usage
