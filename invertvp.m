function  v  = invertvp( dx, n0, mu, v1, vL1, vR1, v2, vL2, vR2 )
    %INVERT tries to find v such that v -> n0 at a chemical potential mu

    vpR = 0; % currently the partition potential is assumed to be zero 
    vpL = 0; % outside the gridded region.  For now vpR and vpL can be 
             % adjusted manually to play around with that assumption.
    
    RelTol = eps;
    AbsTol = eps;
    
    Nelem = numel(n0);
    shoot = solver(Nelem,dx);

    dens = @(E,v,vL,vR) ldos(shoot(E,v,vL,vR));
    resp = @(E,v,vL,vR) response(shoot(E,v,vL,vR));

    E0 = min(v1+v2)-1;

    R = (E0+mu)/2;
    A = mu-R; 
    E = @(theta) R + A*exp(1i*theta);
    dEdt = @(theta) 1i*A*exp(1i*theta);

    v = zeros(Nelem,1);
    
    fprintf(' iter     res_ncon        res_Ncon\n');
    fprintf(' -----------------------------------------\n');
    
    maxiter = 20;
    tol = 1e-13;
    optimality = 1; 
    iter = 0; 
    while iter<=maxiter && optimality>tol;
        [err,grad] = eqn(v);   
        n1;n2;
        optimality = max(abs(err));
        dv = - grad\err;
%         if abs(dv(end))>1
%             dv(end) = sign(dv(end));
%         end
%         if abs(dv(1))>1
%             dv(end) = sign(dv(1));
%         end
        
        v = v + dv; 
        
        fprintf('   %i    %e    %e\n',iter,optimality,sum(err));
        iter = iter+1;   
    end
    
    function [err,grad] = eqn(vp)

        n1 = integral(@(theta) dens(E(theta),v1+vp,vL1+vpL,vR1+vpR)*dEdt(theta),0,pi,...
            'ArrayValued',true,...
            'RelTol',RelTol,...
            'AbsTol',AbsTol);
        n1 = n1+conj(n1);
        
        n2 = integral(@(theta) dens(E(theta),v2+vp,vL2+vpL,vR2+vpR)*dEdt(theta),0,pi,...
            'ArrayValued',true,...
            'RelTol',RelTol,...
            'AbsTol',AbsTol);
        n2 = n2+conj(n2);

        grad1 = dx*integral(@(theta) resp(E(theta),v1+vp,vL1+vpL,vR1+vpR)*dEdt(theta),0,pi,...
                    'ArrayValued',true,...
                    'RelTol',1e-1,...
                    'AbsTol',1e-1);
        grad1 = grad1+conj(grad1);
        
        grad2 = dx*integral(@(theta) resp(E(theta),v2+vp,vL2+vpL,vR2+vpR)*dEdt(theta),0,pi,...
                    'ArrayValued',true,...
                    'RelTol',1e-1,...
                    'AbsTol',1e-1);
        grad2 = grad2+conj(grad2);

        err = n1+n2-n0;
        
        grad = grad1+grad2;
        
    end
end

