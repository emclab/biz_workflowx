module BizWorkflowx
  module WfHelper
    extend ActiveSupport::Concern
    #before_action load the wf action def
    included do
      before_action :load_wf_action_def
    end
    
    def event_action
      @title = t('Event Form') + '-' + t(params[:controller][/\/.+/].sub('/', '').titleize.singularize)  #ex Event Form-Quote
      @workflow_model_object = params[:controller].camelize.singularize.constantize.find_by_id(params[:resource_id])  
      @workflow_result_url =   params[:wf_event].downcase + '_' + params[:controller][/\/.+/].sub('/', '').tableize.singularize + '_path'  #submit_quote_path
      @inline_erb_code = find_config_const(params[:controller][/\/.+/].sub('/', '').singularize+ '_' + params[:wf_event] + '_inline', params[:controller][/.+\//].sub('/', ''))
      #ex, ('quote_submit_inline', 'in_quotex')
      @erb_code = find_config_const('event_action_view', 'biz_workflowx')
    end

    
    protected
    
    def wf_common_action(from, to, event)
      model_sym = params[:controller][/\/.+/].sub('/', '').singularize.to_sym  #ex, :project out of 'projectx/projects'
      model_id = params[model_sym][:id_noupdate].to_i
      @workflow_model_object = params[:controller].camelize.singularize.constantize.find_by_id(model_id) 
      @workflow_model_object.last_updated_by_id = session[:user_id]
      @workflow_model_object.wf_event = event  #pass the event into model. Need to define accessor wf_event in model. 
      @workflow_model_object.transaction do
        if @workflow_model_object.update_attributes(params[model_sym], :as => :role_update)
          @workflow_model_object.send(event.strip + '!')
          StateMachineLogx::StateMachineLogxHelper.state_machine_logger(params[model_sym][:id_noupdate], params[:controller], session[:user_name], params[model_sym][:wf_comment], from, to, event, session[:user_id])
          redirect_to URI.escape(SUBURI + "/view_handler?index=0&msg=State Successfully Updated!")
        else
          params[:resource_id] = params[model_sym][:id_noupdate].to_i
          params[:wf_event] = params[:action]
          @inline_erb_code = find_config_const(params[:controller][/\/.+/].sub('/', '').singularize+ '_' + params[:wf_event] + '_inline', params[:controller][/.+\//].sub('/', ''))
          @workflow_model_object = params[:controller].camelize.singularize.constantize.find_by_id(params[model_sym][:id_noupdate])
          @workflow_result_url =   params[:wf_event].downcase + '_' + params[:controller][/\/.+/].sub('/', '').tableize.singularize + '_path'
          flash.now[:error] = t('Data Error. State Not Saved!')
          render 'event_action'
        end
      end
    end
    
    def load_wf_action_def    
      engine_name = params[:controller][/.+\//].sub('/','')  #in_quotex
      config_var_name = params[:controller][/\/.+/].sub('/','').singularize + '_wf_action_def' #quote_wf_action_def
      wf = Authentify::AuthentifyUtility.find_config_const(config_var_name, engine_name)
      eval(wf) if wf.present? 
      #load the action into Controller.action_methods if not done yet
      wf.split("\n").each {|s| action_methods.add(s.sub('def ', '').strip) if s.include?('def ') && !action_methods.to_a.include?(s.sub('def ', '').strip)} if wf.present?  
    end 
    
    def return_open_process(model, final_state_string)  #string like: 'approved, stamped'
      num_days = find_config_const('wf_list_open_process_in_day').to_i
      state_array = params[:controller].camelize.singularize.constantize.workflow_spec.state_names
      open_state, all_state = [], []
      state_array.each do |s|
        all_state << s.to_s
      end
      open_state = all_state - final_state_string.split(',').map(&:strip) #ex, ['initial_state', 'reviewing']
      #for i in 1..num_of_final_state
      #  open_state = open_state - [all_state[-i]]
      #end
      model.where(params[:controller].sub('/', '_').to_sym => {:wf_state => open_state}).where("#{params[:controller].sub('/', '_')}.created_at >= ?", num_days.days.ago)
    end
    
  end
end